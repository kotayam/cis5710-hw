`timescale 1ns / 1ns

// registers are 32 bits in RV32
`define REG_SIZE 31:0

// insns are 32 bits in RV32IM
`define INSN_SIZE 31:0

// RV opcodes are 7 bits
`define OPCODE_SIZE 6:0

// NOP
`define NOP_INSN 32'h0

`define ADDR_WIDTH 32
`define DATA_WIDTH 32

`ifndef DIVIDER_STAGES
`define DIVIDER_STAGES 8
`endif

`ifndef SYNTHESIS
  `include "../hw3-singlecycle/RvDisassembler.sv"
`endif
`include "../hw2b-cla/CarryLookaheadAdder.sv"
`include "../hw3-singlecycle/cycle_status.sv"
`include "../hw4-multicycle/DividerUnsignedPipelined.sv"
`include "EasyAxilMemory.sv"

module Disasm #(
    PREFIX = "D"
) (
    input wire [31:0] insn,
    output wire [(8*32)-1:0] disasm
);
`ifndef RISCV_FORMAL
`ifndef SYNTHESIS
  // this code is only for simulation, not synthesis
  string disasm_string;
  always_comb begin
    disasm_string = rv_disasm(insn);
  end
  // HACK: get disasm_string to appear in GtkWave, which can apparently show only wire/logic. Also,
  // string needs to be reversed to render correctly.
  genvar i;
  for (i = 3; i < 32; i = i + 1) begin : gen_disasm
    assign disasm[((i+1-3)*8)-1-:8] = disasm_string[31-i];
  end
  assign disasm[255-:8] = PREFIX;
  assign disasm[247-:8] = ":";
  assign disasm[239-:8] = " ";
`endif
`endif
endmodule

module RegFile (
    input logic [4:0] rd,
    input logic [`REG_SIZE] rd_data,
    input logic [4:0] rs1,
    output logic [`REG_SIZE] rs1_data,
    input logic [4:0] rs2,
    output logic [`REG_SIZE] rs2_data,

    input logic clk,
    input logic we,
    input logic rst
);
  localparam int NumRegs = 32;
  logic [`REG_SIZE] regs[NumRegs];

  // x0 is always 0
  assign regs[0] = 32'b0;

  // set rs1 and rs2
  assign rs1_data = regs[rs1];
  assign rs2_data = regs[rs2];

  always_ff @(posedge clk) begin
    if (rst) begin
      for (int i = 1; i < NumRegs; i++) begin
        regs[i] <= 32'b0;
      end
    end else begin
      if (we && rd != 0) begin
        regs[rd] <= rd_data;
      end   
    end
  end
endmodule

/** state at the start of Get stage */
typedef struct packed {
  logic [`REG_SIZE] pc;
  cycle_status_e cycle_status;
} stage_get_t;

/** state at the start of Decode stage */
typedef struct packed {
  logic [`REG_SIZE] pc;
  logic [`INSN_SIZE] insn;
  cycle_status_e cycle_status;
} stage_decode_t;

/** state at the start of Execute stage */
typedef struct packed {
  logic [`REG_SIZE] pc;
  logic [`INSN_SIZE] insn;
  cycle_status_e cycle_status;
  logic [4:0] rd;
  logic [4:0] rs1;
  logic [4:0] rs2;
  logic [`REG_SIZE] rs1_data;
  logic [`REG_SIZE] rs2_data;
} stage_execute_t;

/** state at the start of Memory stage */
typedef struct packed {
  logic [`REG_SIZE] pc;
  logic [`INSN_SIZE] insn;
  logic halt;
  cycle_status_e cycle_status;
  logic [4:0] rd;
  logic [4:0] rs2;
  logic [`REG_SIZE] output_data;
  logic [`REG_SIZE] rs2_data; // needed for store data
} stage_memory_t;

/** state at the start of Writeback stage */
typedef struct packed {
  logic [`REG_SIZE] pc;
  logic [`INSN_SIZE] insn;
  logic halt;
  cycle_status_e cycle_status;
  logic [4:0] rd;
  logic [`REG_SIZE] output_data;
  logic [`REG_SIZE] load_data;
} stage_writeback_t;

module DatapathPipelinedAxil (
    input wire clk,
    input wire rst,

    // interface to insn memory/cache
    axil_if.manager imem,
    // interface to data memory/cache
    axil_if.manager dmem,

    output logic halt,

    // The PC of the insn currently in Writeback. 0 if not a valid insn.
    output logic [`REG_SIZE] trace_completed_pc,
    // The bits of the insn currently in Writeback. 0 if not a valid insn.
    output logic [`INSN_SIZE] trace_completed_insn,
    // The status of the insn (or stall) currently in Writeback. See the cycle_status.sv file for valid values.
    output cycle_status_e trace_completed_cycle_status
);

  localparam bit True = 1'b1;
  localparam bit False = 1'b0;
  
  // opcodes - see section 19 of RiscV spec
  localparam bit [`OPCODE_SIZE] OpLoad = 7'b00_000_11;
  localparam bit [`OPCODE_SIZE] OpStore = 7'b01_000_11;
  localparam bit [`OPCODE_SIZE] OpBranch = 7'b11_000_11;
  localparam bit [`OPCODE_SIZE] OpJalr = 7'b11_001_11;
  localparam bit [`OPCODE_SIZE] OpMiscMem = 7'b00_011_11;
  localparam bit [`OPCODE_SIZE] OpJal = 7'b11_011_11;

  localparam bit [`OPCODE_SIZE] OpRegImm = 7'b00_100_11;
  localparam bit [`OPCODE_SIZE] OpRegReg = 7'b01_100_11;
  localparam bit [`OPCODE_SIZE] OpEnviron = 7'b11_100_11;

  localparam bit [`OPCODE_SIZE] OpAuipc = 7'b00_101_11;
  localparam bit [`OPCODE_SIZE] OpLui = 7'b01_101_11;


  // cycle counter
  logic [`REG_SIZE] cycles_current;
  always_ff @(posedge clk) begin
    if (rst) begin
      cycles_current <= 0;
    end else begin
      cycles_current <= cycles_current + 1;
    end
  end

  /***************/
  /* FETCH STAGE */
  /***************/
  // keep track of branch taken
  wire branch_taken;

  logic [`REG_SIZE] f_pc_current;
  logic [`REG_SIZE] f_pc_next;

  always_comb begin
    imem.ARVALID = True;
    if (branch_taken) begin
      imem.ARVALID = False;
    end
  end
  assign imem.ARADDR = f_pc_current;


  cycle_status_e f_cycle_status;

  // program counter
  always_ff @(posedge clk) begin
    if (rst) begin
      f_pc_current <= 32'd0;
      // NB: use CYCLE_NO_STALL since this is the value that will persist after the last reset cycle
      f_cycle_status <= CYCLE_NO_STALL;
    end else begin
      f_cycle_status <= CYCLE_NO_STALL;
      f_pc_current <= f_pc_next;
    end
  end

  // Here's how to disassemble an insn into a string you can view in GtkWave.
  // Use PREFIX to provide a 1-character tag to identify which stage the insn comes from.
  wire [255:0] f_disasm;
  Disasm #(
      .PREFIX("F")
  ) disasm_0fetch (
      .insn  (0),
      .disasm(f_disasm)
  );

  /*************/
  /* GET STAGE */
  /*************/
  stage_get_t get_state;
  always_ff @(posedge clk) begin
    if (rst) begin
      get_state <= '{
        pc: 0,
        cycle_status: CYCLE_RESET
      };
    end else if (branch_taken) begin
      get_state <= '{
        pc: 0,
        cycle_status: CYCLE_TAKEN_BRANCH
      };
    end else begin
      get_state <= '{
        pc: f_pc_current,
        cycle_status: f_cycle_status
      };
    end 
  end

  logic [`INSN_SIZE] g_insn;
  wire g_valid = imem.RVALID;
  wire g_stall = !g_valid;
  assign imem.RREADY = True; 

  always_comb begin
    g_insn = imem.RDATA;
    if (g_stall) begin
      g_insn = `NOP_INSN;
    end
  end

  wire [255:0] g_disasm;
  Disasm #(
      .PREFIX("G")
  ) disasm_0get (
      .insn  (g_insn),
      .disasm(g_disasm)
  );

  /****************/
  /* DECODE STAGE */
  /****************/

  // keep track of stalls
  logic load_use_stall;
  logic div_stall;
  logic x_stall;
  // compound stall indicator for decode
  logic d_stall;

  // this shows how to package up state in a `struct packed`, and how to pass it between stages
  stage_decode_t decode_state;
  always_ff @(posedge clk) begin
    if (rst) begin
      decode_state <= '{
        pc: 0,
        insn: 0,
        cycle_status: CYCLE_RESET
      };
    end else if (branch_taken) begin
      decode_state <= '{
        pc: 0,
        insn: `NOP_INSN,
        cycle_status: CYCLE_TAKEN_BRANCH
      };
    end else if (d_stall || g_stall) begin
      decode_state <= '{
        pc: decode_state.pc,
        insn: decode_state.insn,
        cycle_status: decode_state.cycle_status
      };
    end else begin
      decode_state <= '{
        pc: get_state.pc,
        insn: g_insn,
        cycle_status: get_state.cycle_status
      };
    end 
  end

  wire [255:0] d_disasm;
  Disasm #(
      .PREFIX("D")
  ) disasm_1decode (
      .insn  (decode_state.insn),
      .disasm(d_disasm)
  );

  logic we;
  logic [4:0] rd;
  logic [`REG_SIZE] rd_data;
  logic [4:0] rs1;
  logic [4:0] rs2;
  wire [`REG_SIZE] rs1_data;
  wire [`REG_SIZE] rs2_data;
  RegFile rf (
    .clk(clk),
    .rst(rst),
    .we(we),
    .rd(rd),
    .rd_data(rd_data),
    .rs1(rs1),
    .rs2(rs2),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data));
  
  // components of the instruction
  wire [`OPCODE_SIZE] d_opcode;
  wire [4:0] insn_rs1;
  wire [4:0] insn_rs2;
  wire [4:0] insn_rd;

  // split R-type instruction - see section 2.2 of RiscV spec
  assign d_opcode = decode_state.insn[6:0];
  assign insn_rd = decode_state.insn[11:7];
  assign insn_rs1 = decode_state.insn[19:15];
  assign insn_rs2 = decode_state.insn[24:20];

  // check if need rs1 or rs2 based on opcode
  logic use_rs1, use_rs2;
  always_comb begin
    case (d_opcode) 
      OpRegImm, OpLoad, OpJalr : begin
        use_rs1 = 1'b1;
        use_rs2 = 1'b0;
      end
      OpRegReg, OpStore, OpBranch: begin
        use_rs1 = 1'b1;
        use_rs2 = 1'b1;
      end
      default: begin
        use_rs1 = 1'b0;
        use_rs2 = 1'b0;
      end 
    endcase
  end

  // get rs1 and rs2 data if needed
  assign rs1 = use_rs1? insn_rs1 : 5'b0;
  assign rs2 = use_rs2? insn_rs2 : 5'b0;

  logic [`REG_SIZE] d_rs1_data, d_rs2_data;
  logic [`REG_SIZE] wd_rs1_data, wd_rs2_data;
  logic wd_bypass_taken;

  // flush decode if branch was taken in execute.
  // use WD bypass if taken.
  always_comb begin
    if (branch_taken) begin
      d_rs1_data = 32'b0;
      d_rs2_data = 32'b0;
    end else if (wd_bypass_taken) begin
      d_rs1_data = wd_rs1_data;
      d_rs2_data = wd_rs2_data;
    end else begin
      d_rs1_data = rs1_data;
      d_rs2_data = rs2_data;
    end
  end

  // clear states on branch taken, load-use stall, or div stall
  logic [`REG_SIZE] d_pc;
  logic [`INSN_SIZE] d_insn;
  cycle_status_e d_cycle_status;
  logic [4:0] d_rd, d_rs1, d_rs2;
  always_comb begin
    d_pc = decode_state.pc;
    d_insn = decode_state.insn;
    d_cycle_status = decode_state.cycle_status;
    d_rd = insn_rd;
    d_rs1 = insn_rs1;
    d_rs2 = insn_rs2;
    if (branch_taken || load_use_stall || div_stall) begin
      d_pc = 32'b0;
      d_insn = `NOP_INSN;
      d_cycle_status = branch_taken? CYCLE_TAKEN_BRANCH : load_use_stall? CYCLE_LOAD2USE : CYCLE_DIV;
      d_rd = 5'b0;
      d_rs1 = 5'b0;
      d_rs2 = 5'b0;
    end
  end

  
  /*****************/
  /* EXECUTE STAGE */
  /*****************/

  stage_execute_t execute_state;
  always_ff @(posedge clk) begin
    if (rst) begin
      execute_state <= '{
        pc: 0,
        insn: 0,
        cycle_status: CYCLE_RESET,
        rd: 5'b0,
        rs1: 5'b0,
        rs2: 5'b0,
        rs1_data: 32'b0,
        rs2_data: 32'b0
      };
    end else if (x_stall) begin
      execute_state <= execute_state;
    end else begin
      execute_state <= '{
        pc: d_pc,
        insn: d_insn,
        cycle_status: d_cycle_status,
        rd: d_rd,
        rs1: d_rs1,
        rs2: d_rs2,
        rs1_data: d_rs1_data,
        rs2_data: d_rs2_data
      };
    end
  end

  wire [255:0] x_disasm;
  Disasm #(
      .PREFIX("X")
  ) disasm_2execute (
      .insn  (execute_state.insn),
      .disasm(x_disasm)
  );
  
  // components of the instruction
  wire [6:0] insn_funct7;
  wire [2:0] insn_funct3;
  wire [`OPCODE_SIZE] insn_opcode;

  // split R-type instruction - see section 2.2 of RiscV spec
  assign insn_opcode = execute_state.insn[6:0];
  assign insn_funct3 = execute_state.insn[14:12];
  assign insn_funct7 = execute_state.insn[31:25];

  // setup for I, S, B & J type instructions
  // I - short immediates and loads
  wire [11:0] imm_i;
  assign imm_i = execute_state.insn[31:20];
  wire [4:0] imm_shamt = execute_state.insn[24:20];

  // S - stores
  wire [11:0] imm_s;
  assign imm_s[11:5] = insn_funct7, imm_s[4:0] = execute_state.rd;

  // B - conditionals
  wire [12:0] imm_b;
  assign {imm_b[12], imm_b[10:5]} = insn_funct7, {imm_b[4:1], imm_b[11]} = execute_state.rd, imm_b[0] = 1'b0;

  // J - unconditional jumps
  wire [20:0] imm_j;
  assign {imm_j[20], imm_j[10:1], imm_j[11], imm_j[19:12], imm_j[0]} = {execute_state.insn[31:12], 1'b0};

  // U-type
  wire [19:0] imm_u;
  assign imm_u = execute_state.insn[31:12];

  wire [`REG_SIZE] imm_i_sext = {{20{imm_i[11]}}, imm_i[11:0]};
  wire [`REG_SIZE] imm_s_sext = {{20{imm_s[11]}}, imm_s[11:0]};
  wire [`REG_SIZE] imm_b_sext = {{19{imm_b[12]}}, imm_b[12:0]};
  wire [`REG_SIZE] imm_j_sext = {{11{imm_j[20]}}, imm_j[20:0]};

  wire insn_lui   = insn_opcode == OpLui;
  wire insn_auipc = insn_opcode == OpAuipc;
  wire insn_jal   = insn_opcode == OpJal;
  wire insn_jalr  = insn_opcode == OpJalr;

  wire insn_beq  = insn_opcode == OpBranch && execute_state.insn[14:12] == 3'b000;
  wire insn_bne  = insn_opcode == OpBranch && execute_state.insn[14:12] == 3'b001;
  wire insn_blt  = insn_opcode == OpBranch && execute_state.insn[14:12] == 3'b100;
  wire insn_bge  = insn_opcode == OpBranch && execute_state.insn[14:12] == 3'b101;
  wire insn_bltu = insn_opcode == OpBranch && execute_state.insn[14:12] == 3'b110;
  wire insn_bgeu = insn_opcode == OpBranch && execute_state.insn[14:12] == 3'b111;

  wire insn_addi  = insn_opcode == OpRegImm && execute_state.insn[14:12] == 3'b000;
  wire insn_slti  = insn_opcode == OpRegImm && execute_state.insn[14:12] == 3'b010;
  wire insn_sltiu = insn_opcode == OpRegImm && execute_state.insn[14:12] == 3'b011;
  wire insn_xori  = insn_opcode == OpRegImm && execute_state.insn[14:12] == 3'b100;
  wire insn_ori   = insn_opcode == OpRegImm && execute_state.insn[14:12] == 3'b110;
  wire insn_andi  = insn_opcode == OpRegImm && execute_state.insn[14:12] == 3'b111;

  wire insn_slli = insn_opcode == OpRegImm && execute_state.insn[14:12] == 3'b001 && execute_state.insn[31:25] == 7'd0;
  wire insn_srli = insn_opcode == OpRegImm && execute_state.insn[14:12] == 3'b101 && execute_state.insn[31:25] == 7'd0;
  wire insn_srai = insn_opcode == OpRegImm && execute_state.insn[14:12] == 3'b101 && execute_state.insn[31:25] == 7'b0100000;

  wire insn_add  = insn_opcode == OpRegReg && execute_state.insn[14:12] == 3'b000 && execute_state.insn[31:25] == 7'd0;
  wire insn_sub  = insn_opcode == OpRegReg && execute_state.insn[14:12] == 3'b000 && execute_state.insn[31:25] == 7'b0100000;
  wire insn_sll  = insn_opcode == OpRegReg && execute_state.insn[14:12] == 3'b001 && execute_state.insn[31:25] == 7'd0;
  wire insn_slt  = insn_opcode == OpRegReg && execute_state.insn[14:12] == 3'b010 && execute_state.insn[31:25] == 7'd0;
  wire insn_sltu = insn_opcode == OpRegReg && execute_state.insn[14:12] == 3'b011 && execute_state.insn[31:25] == 7'd0;
  wire insn_xor  = insn_opcode == OpRegReg && execute_state.insn[14:12] == 3'b100 && execute_state.insn[31:25] == 7'd0;
  wire insn_srl  = insn_opcode == OpRegReg && execute_state.insn[14:12] == 3'b101 && execute_state.insn[31:25] == 7'd0;
  wire insn_sra  = insn_opcode == OpRegReg && execute_state.insn[14:12] == 3'b101 && execute_state.insn[31:25] == 7'b0100000;
  wire insn_or   = insn_opcode == OpRegReg && execute_state.insn[14:12] == 3'b110 && execute_state.insn[31:25] == 7'd0;
  wire insn_and  = insn_opcode == OpRegReg && execute_state.insn[14:12] == 3'b111 && execute_state.insn[31:25] == 7'd0;

  wire insn_mul    = insn_opcode == OpRegReg && execute_state.insn[31:25] == 7'd1 && execute_state.insn[14:12] == 3'b000;
  wire insn_mulh   = insn_opcode == OpRegReg && execute_state.insn[31:25] == 7'd1 && execute_state.insn[14:12] == 3'b001;
  wire insn_mulhsu = insn_opcode == OpRegReg && execute_state.insn[31:25] == 7'd1 && execute_state.insn[14:12] == 3'b010;
  wire insn_mulhu  = insn_opcode == OpRegReg && execute_state.insn[31:25] == 7'd1 && execute_state.insn[14:12] == 3'b011;
  wire insn_div    = insn_opcode == OpRegReg && execute_state.insn[31:25] == 7'd1 && execute_state.insn[14:12] == 3'b100;
  wire insn_divu   = insn_opcode == OpRegReg && execute_state.insn[31:25] == 7'd1 && execute_state.insn[14:12] == 3'b101;
  wire insn_rem    = insn_opcode == OpRegReg && execute_state.insn[31:25] == 7'd1 && execute_state.insn[14:12] == 3'b110;
  wire insn_remu   = insn_opcode == OpRegReg && execute_state.insn[31:25] == 7'd1 && execute_state.insn[14:12] == 3'b111;
  wire insn_ecall = insn_opcode == OpEnviron && execute_state.insn[31:7] == 25'd0;
  wire insn_fence = insn_opcode == OpMiscMem;





  // CLA for ALU operations.
  logic [`REG_SIZE] alu_a, alu_b, alu_sum;
  logic alu_cin;
  CarryLookaheadAdder alu_cla (
    .a(alu_a),
    .b(alu_b),
    .cin(alu_cin),
    .sum(alu_sum)
  );

  logic [`REG_SIZE] bypassed_rs1_data, bypassed_rs2_data;

  always_comb begin
    // alu_a
    case (insn_opcode)
      OpJal: begin
        alu_a = execute_state.pc;
      end
      OpLui: begin
        alu_a = 32'b0;
      end
      default: begin
        alu_a = bypassed_rs1_data;
      end
    endcase
    // alu_b
    case (insn_opcode)
      OpRegImm, OpLoad, OpJalr : begin
        alu_b = imm_i_sext;
      end
      OpStore: begin
        alu_b = imm_s_sext;
      end
      OpLui: begin
        alu_b = imm_u << 12;
      end
      OpJal: begin
        alu_b = 32'd4;
      end
      OpRegReg : begin
        if (insn_sub) begin
          alu_b = ~bypassed_rs2_data;
        end else begin
          alu_b = bypassed_rs2_data;
        end
      end
      default : begin
        alu_b = bypassed_rs2_data;
      end
    endcase
  end

  // divider logic
  logic [`REG_SIZE] div_dividend, div_divisor;
  wire [`REG_SIZE] div_quotient_raw, div_remainder_raw;
  DividerUnsignedPipelined divider (
      .clk(clk),
      .rst(rst),
      .stall(1'b0), 
      .i_dividend(div_dividend),
      .i_divisor(div_divisor),
      .o_remainder(div_remainder_raw),
      .o_quotient(div_quotient_raw)
  );

  // true if insn uses divider
  wire insn_uses_divider = insn_div || insn_divu || insn_rem || insn_remu;

  logic is_signed_div;
  assign is_signed_div = insn_div || insn_rem;

  logic div_by_zero, div_overflow, want_neg_quotient, want_neg_remainder;

  always_comb begin
    div_by_zero = (alu_b == 32'b0);
    div_overflow = is_signed_div && (alu_a == 32'h80000000) && (alu_b == 32'hFFFFFFFF);

    if (is_signed_div) begin
      // take absolute values for unsigned hardware divider
      div_dividend = (alu_a[31]) ? (~alu_a + 32'd1) : alu_a;
      div_divisor  = (alu_b[31]) ? (~alu_b + 32'd1) : alu_b;
      // determine final signs
      want_neg_quotient = (alu_a[31] != alu_b[31]) && !div_by_zero && !div_overflow;
      want_neg_remainder = alu_a[31]; // Remainder sign matches dividend
    end else begin
      div_dividend = alu_a;
      div_divisor  = alu_b;
      want_neg_quotient = 1'b0;
      want_neg_remainder = 1'b0;
    end
  end

  // divider tracking shift register 
  typedef struct packed {
    logic valid;
    logic [4:0] rd;
    logic [`REG_SIZE] pc;
    logic [`INSN_SIZE] insn;
    cycle_status_e cycle_status;
    logic halt;
    logic div_by_zero;
    logic div_overflow;
    logic want_neg_quotient;
    logic want_neg_remainder;
    logic [`REG_SIZE] orig_alu_a;
  } div_track_t;

  div_track_t [6:0] div_sr;
  
  wire div_in_flight = div_sr[0].valid || div_sr[1].valid || div_sr[2].valid || div_sr[3].valid || div_sr[4].valid || div_sr[5].valid || div_sr[6].valid;

  always_ff @(posedge clk) begin
    if (rst) begin
      for (int i = 0; i < 7; i++) div_sr[i] <= '{valid: 0, cycle_status: CYCLE_RESET, default: 0};
    end else begin
      // shift pipeline
      for (int i = 1; i < 7; i++) div_sr[i] <= div_sr[i-1];
      
      // enter from execute stage (X0)
      if (execute_state.cycle_status == CYCLE_NO_STALL && insn_uses_divider) begin
        div_sr[0] <= '{
          valid: 1'b1,
          rd: execute_state.rd,
          pc: execute_state.pc,
          insn: execute_state.insn,
          cycle_status: execute_state.cycle_status,
          halt: x_halt,
          div_by_zero: div_by_zero,
          div_overflow: div_overflow,
          want_neg_quotient: want_neg_quotient,
          want_neg_remainder: want_neg_remainder,
          orig_alu_a: bypassed_rs1_data
        };
      end else begin
        div_sr[0] <= '{valid: 1'b0, cycle_status: CYCLE_NO_STALL, default: 0};
      end
    end
  end

  // Multiplication
  logic [63:0] mul_res_signed, mul_res_unsigned, mul_res_su;
  assign mul_res_signed   = $signed(alu_a) * $signed(alu_b);
  assign mul_res_unsigned = alu_a * alu_b;
  assign mul_res_su       = $signed(alu_a) * $signed({1'b0, alu_b});

  logic illegal_insn;

  logic [`REG_SIZE] x_output_data;
  logic [`REG_SIZE] x_rs2_data;
  logic x_branch_taken;
  logic x_halt;

  logic [`REG_SIZE] addr_to_dmem;
  

  always_comb begin
    // set defaults
    illegal_insn = 1'b0;

    // ALU CLA defaults
    alu_cin = 1'b0;

    // default halt to 0
    x_halt = 1'b0;

    // increment pc by 4 default
    // don't update PC if stall
    f_pc_next = d_stall? f_pc_current : f_pc_current + 32'd4;

    x_output_data = 32'b0;
    x_rs2_data = execute_state.rs2_data;
    x_branch_taken = 1'b0;
    addr_to_dmem = 32'b0;
    dmem.AWADDR = 32'b0;
    dmem.AWVALID = 0;
    dmem.ARADDR = 32'b0;
    dmem.ARVALID = 0;
    
    case (insn_opcode)
      OpLui: begin
        x_output_data = imm_u << 12;
      end
      OpAuipc: begin
        x_output_data = execute_state.pc + (imm_u << 12);
      end
      OpRegImm: begin
        if (insn_addi) begin
          x_output_data = alu_sum;
        end else if (insn_slti) begin
          x_output_data = $signed(alu_a) < $signed(imm_i_sext) ? 32'd1 : 32'd0;
        end else if (insn_sltiu) begin
          x_output_data = alu_a < imm_i_sext ? 32'd1 : 32'd0;
        end else if (insn_xori) begin
          x_output_data = alu_a ^ imm_i_sext;
        end else if (insn_ori) begin
          x_output_data = alu_a | imm_i_sext;
        end else if (insn_andi) begin
          x_output_data = alu_a & imm_i_sext;
        end else if (insn_slli) begin
          x_output_data = alu_a << imm_shamt;
        end else if (insn_srli) begin
          x_output_data = alu_a >> imm_shamt;
        end else if (insn_srai) begin
          x_output_data = $signed(alu_a) >>> imm_shamt;
        end else begin
          illegal_insn = 1'b1;
        end
      end
      OpRegReg: begin
        if (insn_mul) begin
            x_output_data = mul_res_signed[31:0];
        end else if (insn_mulh) begin
            x_output_data = mul_res_signed[63:32];
        end else if (insn_mulhsu) begin
            x_output_data = mul_res_su[63:32];
        end else if (insn_mulhu) begin
            x_output_data = mul_res_unsigned[63:32];
        end else if (insn_add) begin
          x_output_data = alu_sum;
        end else if (insn_sub) begin
          alu_cin = 1'b1;
          x_output_data = alu_sum;
        end else if (insn_sll) begin
          x_output_data = alu_a << alu_b[4:0];
        end else if (insn_slt) begin
          x_output_data = $signed(alu_a) < $signed(alu_b) ? 32'd1 : 32'd0;
        end else if (insn_sltu) begin
          x_output_data = alu_a < alu_b ? 32'd1 : 32'd0;
        end else if (insn_xor) begin
          x_output_data = alu_a ^ alu_b;
        end else if (insn_srl) begin
          x_output_data = alu_a >> alu_b[4:0];
        end else if (insn_sra) begin
          x_output_data = $signed(alu_a) >>> alu_b[4:0];
        end else if (insn_or) begin
          x_output_data = alu_a | alu_b;
        end else if (insn_and) begin
          x_output_data = alu_a & alu_b;
        end else begin
          illegal_insn = 1'b1;
        end
      end
      OpStore, OpLoad: begin
        x_output_data = alu_a + alu_b;
        x_rs2_data = bypassed_rs2_data;
        // make sure 4B aligned
        addr_to_dmem = {x_output_data[31:2], 2'b00};
        if (insn_opcode == OpStore) begin
          dmem.AWADDR = x_output_data;
          dmem.AWVALID = 1;

        end
        else begin
          dmem.ARADDR = x_output_data;
          dmem.ARVALID = 1;
        end
      end
      OpJal: begin
          x_branch_taken = 1'b1;
          x_output_data = execute_state.pc + 32'd4;
          f_pc_next = execute_state.pc + $signed(imm_j_sext);
      end
      OpJalr: begin
          x_branch_taken = 1'b1;
          x_output_data = execute_state.pc + 32'd4;
          f_pc_next = (alu_a + $signed(imm_i_sext)) & ~32'b1;
      end
      OpBranch: begin
        if (insn_beq) begin
          if (alu_a == alu_b) begin
            x_branch_taken = 1'b1;
            f_pc_next = execute_state.pc + imm_b_sext;
          end
        end else if (insn_bne) begin
          if (alu_a != alu_b) begin
            x_branch_taken = 1'b1;
            f_pc_next = execute_state.pc + imm_b_sext;
          end
        end else if (insn_blt) begin
          if ($signed(alu_a) < $signed(alu_b)) begin
            x_branch_taken = 1'b1;
            f_pc_next = execute_state.pc + imm_b_sext;
          end
        end else if (insn_bge) begin
          if ($signed(alu_a) >= $signed(alu_b)) begin
            x_branch_taken = 1'b1;
            f_pc_next = execute_state.pc + imm_b_sext;
          end
        end else if (insn_bltu) begin
          if (alu_a < alu_b) begin
            x_branch_taken = 1'b1;
            f_pc_next = execute_state.pc + imm_b_sext;
          end
        end else if (insn_bgeu) begin
          if (alu_a >= alu_b) begin
            x_branch_taken = 1'b1;
            f_pc_next = execute_state.pc + imm_b_sext;
          end
        end else begin
          illegal_insn = 1'b1;
        end
      end
      OpEnviron: begin
        if (insn_ecall) begin
          x_halt = 1'b1;
        end else begin
          illegal_insn = 1'b1;
        end
      end
      default: begin
        illegal_insn = 1'b1;
      end
    endcase
  end

  // flush decode and execute if branch was taken in execute
  assign branch_taken = x_branch_taken;

  // load-use stall logic
  wire dependent_d_rs1 = use_rs1 && execute_state.rd == insn_rs1; 
  wire dependent_d_rs2 = use_rs2 && execute_state.rd == insn_rs2;
  always_comb begin
    load_use_stall = 0;
    if (execute_state.rd != 0 && insn_opcode == OpLoad) begin
      if (dependent_d_rs1 || dependent_d_rs2 && d_opcode != OpStore) load_use_stall = 1'b1;
    end
  end

  // div stall logic
  always_comb begin
    div_stall = 0;
    // divider data hazard (div used in execute)
    if (execute_state.rd != 0 && insn_uses_divider) begin
      if (dependent_d_rs1 || dependent_d_rs2) div_stall = 1'b1;
    end
    
    // divider data hazard (div in pipeline)
    // we dont check the last one to prevent cycle delay
    for (int i = 0; i < 6; i++) begin
      if (div_sr[i].valid && div_sr[i].rd != 0) begin
        if ((use_rs1 && insn_rs1 == div_sr[i].rd) || (use_rs2 && insn_rs2 == div_sr[i].rd)) begin
          div_stall = 1'b1;
        end
      end
    end
  end
  
  // execute stalls if non-div insn and old div is in progress
  assign x_stall = execute_state.cycle_status == CYCLE_NO_STALL && !insn_uses_divider && div_in_flight;
  assign d_stall = load_use_stall || div_stall || x_stall;

  /****************/
  /* MEMORY STAGE */
  /****************/

  stage_memory_t m_next;
  always_comb begin
    if (div_sr[6].valid) begin
      m_next = '{
        pc: div_sr[6].pc,
        insn: div_sr[6].insn,
        halt: div_sr[6].halt,
        cycle_status: div_sr[6].cycle_status,
        rd: div_sr[6].rd, 
        rs2: 5'b0,
        output_data: div_out,
        rs2_data: 32'b0
      };
    end else if (div_in_flight || (execute_state.cycle_status == CYCLE_NO_STALL && insn_uses_divider)) begin
      // memroy stage is empty while division runs
      m_next = '{
        pc: 32'b0,
        insn: `NOP_INSN,
        halt: 1'b0,
        cycle_status: CYCLE_DIV, 
        rd: 5'b0,
        rs2: 5'b0,
        output_data: 32'b0,
        rs2_data: 32'b0
      };
    end else begin
      // normal flow from execute
      m_next = '{
        pc: execute_state.pc,
        insn: execute_state.insn,
        halt: x_halt,
        cycle_status: execute_state.cycle_status,
        rd: execute_state.rd,
        rs2: execute_state.rs2,
        output_data: x_output_data, 
        rs2_data: x_rs2_data
      };
    end
  end

  stage_memory_t memory_state;
  always_ff @(posedge clk) begin
    if (rst) begin
      memory_state <= '{
        pc: 0,
        insn: 0,
        halt: 0,
        cycle_status: CYCLE_RESET,
        rd: 5'b0,
        rs2: 5'b0,
        output_data: 32'b0,
        rs2_data: 32'b0
      };
    end else begin 
      memory_state <= m_next;
    end
  end

  wire [255:0] m_disasm;
  Disasm #(
      .PREFIX("M")
  ) disasm_3memory (
      .insn  (memory_state.insn),
      .disasm(m_disasm)
  );

  wire [`OPCODE_SIZE] m_insn_opcode = memory_state.insn[6:0];

  wire insn_lb  = m_insn_opcode == OpLoad && memory_state.insn[14:12] == 3'b000;
  wire insn_lh  = m_insn_opcode == OpLoad && memory_state.insn[14:12] == 3'b001;
  wire insn_lw  = m_insn_opcode == OpLoad && memory_state.insn[14:12] == 3'b010;
  wire insn_lbu = m_insn_opcode == OpLoad && memory_state.insn[14:12] == 3'b100;
  wire insn_lhu = m_insn_opcode == OpLoad && memory_state.insn[14:12] == 3'b101;

  wire insn_sb = m_insn_opcode == OpStore && memory_state.insn[14:12] == 3'b000;
  wire insn_sh = m_insn_opcode == OpStore && memory_state.insn[14:12] == 3'b001;
  wire insn_sw = m_insn_opcode == OpStore && memory_state.insn[14:12] == 3'b010;

  logic [`REG_SIZE] full_addr_to_dmem;
  logic [7:0] byte_val_dmem;
  logic [15:0] half_val_dmem;

  logic [`REG_SIZE] m_load_data;
  logic [`REG_SIZE] m_rs2_data;

  // WM bypass logic
  logic wm_bypass_taken;
  logic [`REG_SIZE] wm_rs2_data;
  wire [`REG_SIZE] m_rdata = dmem.RDATA;

  always_comb begin
    m_load_data = 32'b0;
    
    m_rs2_data = memory_state.rs2_data;
    if (wm_bypass_taken) begin
      m_rs2_data = wm_rs2_data;
    end

    full_addr_to_dmem = 32'b0;
    dmem.WSTRB = 4'b0;
    dmem.WDATA = 32'b0;
    dmem.WVALID = 1'b0;

    case (m_insn_opcode)
      OpLoad: begin
        full_addr_to_dmem = memory_state.output_data;
        
        // for lb
        case (full_addr_to_dmem[1:0])
          2'b00: byte_val_dmem = m_rdata[7:0];
          2'b01: byte_val_dmem = m_rdata[15:8];
          2'b10: byte_val_dmem = m_rdata[23:16];
          2'b11: byte_val_dmem = m_rdata[31:24];
        endcase
        // for lh
        if (full_addr_to_dmem[1]) begin
          half_val_dmem = m_rdata[31:16];
        end else begin
          half_val_dmem = m_rdata[15:0];
        end
        if (insn_lb) begin
          m_load_data = {{24{byte_val_dmem[7]}}, byte_val_dmem};
        end else if (insn_lh) begin
          m_load_data = {{16{half_val_dmem[15]}}, half_val_dmem};
        end else if (insn_lw) begin
          m_load_data = m_rdata;
        end else if (insn_lbu) begin
          m_load_data = {24'b0, byte_val_dmem};
        end else if (insn_lhu) begin
          m_load_data = {16'b0, half_val_dmem};
        end
      end
      OpStore: begin
        full_addr_to_dmem = memory_state.output_data;
        dmem.WVALID = 1'b1;
        if (insn_sb) begin
          case (full_addr_to_dmem[1:0])
            2'b00: dmem.WSTRB = 4'b0001;
            2'b01: dmem.WSTRB = 4'b0010;
            2'b10: dmem.WSTRB = 4'b0100;
            2'b11: dmem.WSTRB = 4'b1000;
          endcase
          dmem.WDATA = {4{m_rs2_data[7:0]}};
        end else if (insn_sh) begin
          if (full_addr_to_dmem[1]) begin
            dmem.WSTRB = 4'b1100;
          end else begin
            dmem.WSTRB = 4'b0011;
          end
          dmem.WDATA = {2{m_rs2_data[15:0]}};
        end else if (insn_sw) begin
          dmem.WSTRB = 4'b1111;
          dmem.WDATA = m_rs2_data;
        end
      end
      default: begin
      end
    endcase
  end

  // get the output data from divicer if ready
  wire [6:0] div_out_funct7 = div_sr[6].insn[31:25];
  wire [2:0] div_out_funct3 = div_sr[6].insn[14:12];

  wire div_out_insn_div  = (div_out_funct7 == 7'd1) && (div_out_funct3 == 3'b100);
  wire div_out_insn_divu = (div_out_funct7 == 7'd1) && (div_out_funct3 == 3'b101);
  wire div_out_insn_rem  = (div_out_funct7 == 7'd1) && (div_out_funct3 == 3'b110);
  wire div_out_insn_remu = (div_out_funct7 == 7'd1) && (div_out_funct3 == 3'b111);

  logic [`REG_SIZE] div_out;
  always_comb begin
    div_out = 32'd0;
    if (div_sr[6].valid) begin
      if (div_out_insn_div) begin
          if (div_sr[6].div_by_zero) div_out = 32'hFFFFFFFF;
          else if (div_sr[6].div_overflow) div_out = 32'h80000000;
          else div_out = div_sr[6].want_neg_quotient ? (~div_quotient_raw + 32'd1) : div_quotient_raw;
      end else if (div_out_insn_divu) begin
          if (div_sr[6].div_by_zero) div_out = 32'hFFFFFFFF;
          else div_out = div_quotient_raw;
      end else if (div_out_insn_rem) begin
          if (div_sr[6].div_by_zero) div_out = div_sr[6].orig_alu_a;
          else if (div_sr[6].div_overflow) div_out = 32'h0;
          else div_out = div_sr[6].want_neg_remainder ? (~div_remainder_raw + 32'd1) : div_remainder_raw;
      end else if (div_out_insn_remu) begin
          if (div_sr[6].div_by_zero) div_out = div_sr[6].orig_alu_a;
          else div_out = div_remainder_raw;
      end
    end
  end

  /*******************/
  /* WRITEBACK STAGE */
  /*******************/

  stage_writeback_t writeback_state;
  always_ff @(posedge clk) begin
    if (rst) begin
      writeback_state <= '{
        pc: 0,
        insn: 0,
        halt: 0,
        cycle_status: CYCLE_RESET,
        rd: 5'b0,
        output_data: 32'b0,
        load_data: 32'b0
      };
    end else begin
      writeback_state <= '{
        pc: memory_state.pc,
        insn: memory_state.insn,
        halt: memory_state.halt,
        cycle_status: memory_state.cycle_status,
        rd: memory_state.rd,
        output_data: memory_state.output_data, 
        load_data: m_load_data
      };
    end
  end

  wire [255:0] w_disasm;
  Disasm #(
      .PREFIX("W")
  ) disasm_4writeback (
      .insn  (writeback_state.insn),
      .disasm(w_disasm)
  );

  logic [`REG_SIZE] w_rd_data;
  wire [`OPCODE_SIZE] w_insn_opcode = writeback_state.insn[6:0];
  assign rd = writeback_state.rd;
  assign halt = writeback_state.halt;

  // choose appropriate data to write back
  always_comb begin
    we = 1'b0;
    w_rd_data = writeback_state.output_data;
    // only write back if valid instruction
    if (writeback_state.cycle_status == CYCLE_NO_STALL) begin
      we = 1'b1;
      case (w_insn_opcode)
        OpLoad: begin
          w_rd_data = writeback_state.load_data;
        end
        OpStore, OpBranch, OpEnviron: begin
          we = 1'b0;
        end
        default : begin
        end
      endcase
    end
  end

  // handle bypass logics
  wire can_mx_bypass = memory_state.rd != 0 && m_insn_opcode != OpStore && m_insn_opcode != OpBranch;
  always_comb begin
    if (can_mx_bypass && memory_state.rd == execute_state.rs1) begin
      // mx bypass for rs1
      bypassed_rs1_data = memory_state.output_data;
    end else if (we && writeback_state.rd != 0 && writeback_state.rd == execute_state.rs1) begin
      // wx bypass for rs1
      bypassed_rs1_data = w_rd_data;
    end else begin
      // no bypass for rs1
      bypassed_rs1_data = execute_state.rs1_data;
    end

    if (can_mx_bypass && memory_state.rd == execute_state.rs2) begin
      // mx bypass for rs2
      bypassed_rs2_data = memory_state.output_data;
    end else if (we && writeback_state.rd != 0 && writeback_state.rd == execute_state.rs2) begin
      // wx bypass for rs2
      bypassed_rs2_data = w_rd_data;
    end else begin
      // no bypass for rs2
      bypassed_rs2_data = execute_state.rs2_data;
    end
  end

  // WD bypass logic
  always_comb begin
    wd_bypass_taken = 1'b0;
    wd_rs1_data = rs1_data;
    wd_rs2_data = rs2_data;
    if (writeback_state.rd != 0 && we) begin
      if (writeback_state.rd == d_rs1) begin
        // we use bypass
        wd_bypass_taken = 1'b1;
        wd_rs1_data = w_rd_data;
      end
      if (writeback_state.rd == d_rs2) begin
        // we use bypass
        wd_bypass_taken = 1'b1;
        wd_rs2_data = w_rd_data;
      end
    end
  end

  // WM bypass logic
  wire wm_dep = w_insn_opcode == OpLoad && m_insn_opcode == OpStore && writeback_state.rd == memory_state.rs2;
  always_comb begin
    wm_bypass_taken = 1'b0;
    wm_rs2_data = memory_state.rs2_data;
    if (writeback_state.rd != 0 && we) begin
      if (wm_dep) begin
        wm_bypass_taken = 1'b1;
        wm_rs2_data = w_rd_data;
      end
    end
  end

  assign rd_data = w_rd_data;

  // assign outputs
  assign trace_completed_pc = writeback_state.pc;
  assign trace_completed_insn = writeback_state.insn;
  assign trace_completed_cycle_status = writeback_state.cycle_status;
endmodule // DatapathPipelinedCache

/* This design has just one clock for both processor and memory. */
module Processor (
    input  wire  clk,
    input  wire  rst,
    output logic halt,
    output wire [`REG_SIZE] trace_completed_pc,
    output wire [`INSN_SIZE] trace_completed_insn,
    output cycle_status_e trace_completed_cycle_status
);

  // This wire is set by cocotb to the name of the currently-running test, to make it easier
  // to see what is going on in the waveforms.
  wire [(8*32)-1:0] test_case;

  axil_if axil_mem_ro ();
  axil_if axil_mem_rw ();

  EasyAxilMemory #(
      .OPT_SKIDBUFFER(1),
      .OPT_LOWPOWER(0),
      .NUM_WORDS(8192)
  ) memory (
      .ACLK(clk),
      .ARESETn(~rst),
      .port_ro(axil_mem_ro.subord),
      .port_rw(axil_mem_rw.subord)
  );

  DatapathPipelinedAxil datapath (
      .clk(clk),
      .rst(rst),
      .imem(axil_mem_ro.manager),
      .dmem(axil_mem_rw.manager),
      .halt(halt),
      .trace_completed_pc(trace_completed_pc),
      .trace_completed_insn(trace_completed_insn),
      .trace_completed_cycle_status(trace_completed_cycle_status)
  );

endmodule
