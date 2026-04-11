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

// TODO: copy over your RegFile and pipeline structs from HW5

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
  // localparam bit False = 1'b0;
  
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

  // TODO: copy in your HW5B datapath as a starting point

  /***************/
  /* FETCH STAGE */
  /***************/

  logic [`REG_SIZE] f_pc_current;
  logic [`REG_SIZE] f_pc_next;
  // logic [`REG_SIZE] f_insn;
  assign imem.ARVALID = True; // always ready to fetch an insn
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
    end else begin
      get_state <= '{
        pc: f_pc_current,
        cycle_status: f_cycle_status
      };
    end 
  end

  wire [`INSN_SIZE] g_insn = imem.RDATA;
  wire g_valid = imem.RVALID;
  assign imem.RREADY = True; 

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

  // keep track of branch taken
  wire branch_taken;
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
    end else if (d_stall) begin
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
