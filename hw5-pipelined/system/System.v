module MyClockGen (
	input_clk_25MHz,
	clk_proc,
	locked
);
	input input_clk_25MHz;
	output wire clk_proc;
	output wire locked;
	wire clkfb;
	(* FREQUENCY_PIN_CLKI = "25" *) (* FREQUENCY_PIN_CLKOP = "20" *) (* ICP_CURRENT = "12" *) (* LPF_RESISTOR = "8" *) (* MFG_ENABLE_FILTEROPAMP = "1" *) (* MFG_GMCREF_SEL = "2" *) EHXPLLL #(
		.PLLRST_ENA("DISABLED"),
		.INTFB_WAKE("DISABLED"),
		.STDBY_ENABLE("DISABLED"),
		.DPHASE_SOURCE("DISABLED"),
		.OUTDIVIDER_MUXA("DIVA"),
		.OUTDIVIDER_MUXB("DIVB"),
		.OUTDIVIDER_MUXC("DIVC"),
		.OUTDIVIDER_MUXD("DIVD"),
		.CLKI_DIV(5),
		.CLKOP_ENABLE("ENABLED"),
		.CLKOP_DIV(30),
		.CLKOP_CPHASE(15),
		.CLKOP_FPHASE(0),
		.FEEDBK_PATH("INT_OP"),
		.CLKFB_DIV(4)
	) pll_i(
		.RST(1'b0),
		.STDBY(1'b0),
		.CLKI(input_clk_25MHz),
		.CLKOP(clk_proc),
		.CLKFB(clkfb),
		.CLKINTFB(clkfb),
		.PHASESEL0(1'b0),
		.PHASESEL1(1'b0),
		.PHASEDIR(1'b1),
		.PHASESTEP(1'b1),
		.PHASELOADREG(1'b1),
		.PLLWAKESYNC(1'b0),
		.ENCLKOP(1'b0),
		.LOCK(locked)
	);
endmodule
module gp1 (
	a,
	b,
	g,
	p
);
	input wire a;
	input wire b;
	output wire g;
	output wire p;
	assign g = a & b;
	assign p = a | b;
endmodule
module gpn (
	gin,
	pin,
	cin,
	gout,
	pout,
	cout
);
	parameter N = 4;
	input wire [N - 1:0] gin;
	input wire [N - 1:0] pin;
	input wire cin;
	output wire gout;
	output wire pout;
	output wire [N - 2:0] cout;
	assign pout = &pin;
	genvar _gv_i_1;
	wire [N - 1:0] tmp_out;
	generate
		for (_gv_i_1 = 0; _gv_i_1 < (N - 1); _gv_i_1 = _gv_i_1 + 1) begin : genblk1
			localparam i = _gv_i_1;
			assign tmp_out[i] = gin[i] & (&pin[N - 1:i + 1]);
		end
	endgenerate
	assign tmp_out[N - 1] = gin[N - 1];
	assign gout = |tmp_out;
	assign cout[0] = gin[0] | (pin[0] & cin);
	genvar _gv_j_1;
	generate
		for (_gv_j_1 = 1; _gv_j_1 < (N - 1); _gv_j_1 = _gv_j_1 + 1) begin : genblk2
			localparam j = _gv_j_1;
			wire [j + 1:0] tmp_cout;
			assign tmp_cout[0] = gin[j];
			assign tmp_cout[1] = pin[j] & gin[j - 1];
			assign tmp_cout[j + 1] = &pin[j:0] & cin;
			genvar _gv_k_1;
			for (_gv_k_1 = 0; _gv_k_1 < (j - 1); _gv_k_1 = _gv_k_1 + 1) begin : genblk1
				localparam k = _gv_k_1;
				assign tmp_cout[2 + k] = &pin[j-:2 + k] & gin[(j - 2) - k];
			end
			assign cout[j] = |tmp_cout;
		end
	endgenerate
endmodule
module gp4 (
	gin,
	pin,
	cin,
	gout,
	pout,
	cout
);
	input wire [3:0] gin;
	input wire [3:0] pin;
	input wire cin;
	output wire gout;
	output wire pout;
	output wire [2:0] cout;
	gpn #(.N(4)) g4(
		.gin(gin),
		.pin(pin),
		.cin(cin),
		.gout(gout),
		.pout(pout),
		.cout(cout)
	);
endmodule
module gp8 (
	gin,
	pin,
	cin,
	gout,
	pout,
	cout
);
	input wire [7:0] gin;
	input wire [7:0] pin;
	input wire cin;
	output wire gout;
	output wire pout;
	output wire [6:0] cout;
	gpn #(.N(8)) g8(
		.gin(gin),
		.pin(pin),
		.cin(cin),
		.gout(gout),
		.pout(pout),
		.cout(cout)
	);
endmodule
module CarryLookaheadAdder (
	a,
	b,
	cin,
	sum
);
	input wire [31:0] a;
	input wire [31:0] b;
	input wire cin;
	output wire [31:0] sum;
	genvar _gv_i_2;
	wire [31:0] g;
	wire [31:0] p;
	generate
		for (_gv_i_2 = 0; _gv_i_2 < 32; _gv_i_2 = _gv_i_2 + 1) begin : genblk1
			localparam i = _gv_i_2;
			gp1 gp_inst(
				.a(a[i]),
				.b(b[i]),
				.g(g[i]),
				.p(p[i])
			);
		end
	endgenerate
	genvar _gv_j_2;
	wire [23:0] couts4;
	wire [7:0] g4;
	wire [7:0] p4;
	wire [7:0] cin4;
	assign cin4[0] = cin;
	generate
		for (_gv_j_2 = 0; _gv_j_2 < 8; _gv_j_2 = _gv_j_2 + 1) begin : genblk2
			localparam j = _gv_j_2;
			gp4 gp4_inst(
				.gin(g[j * 4+:4]),
				.pin(p[j * 4+:4]),
				.cin(cin4[j]),
				.gout(g4[j]),
				.pout(p4[j]),
				.cout(couts4[j * 3+:3])
			);
		end
	endgenerate
	wire g8;
	wire p8;
	wire [6:0] couts8;
	gp8 gp8_inst(
		.gin(g4),
		.pin(p4),
		.cin(cin),
		.gout(g8),
		.pout(p8),
		.cout(couts8)
	);
	genvar _gv_n_1;
	generate
		for (_gv_n_1 = 0; _gv_n_1 < 7; _gv_n_1 = _gv_n_1 + 1) begin : genblk3
			localparam n = _gv_n_1;
			assign cin4[n + 1] = couts8[n];
		end
	endgenerate
	wire [31:0] couts;
	assign couts[0] = cin;
	genvar _gv_k_2;
	generate
		for (_gv_k_2 = 0; _gv_k_2 < 8; _gv_k_2 = _gv_k_2 + 1) begin : genblk4
			localparam k = _gv_k_2;
			genvar _gv_l_1;
			for (_gv_l_1 = 0; _gv_l_1 < 3; _gv_l_1 = _gv_l_1 + 1) begin : genblk1
				localparam l = _gv_l_1;
				assign couts[((k * 4) + l) + 1] = couts4[(k * 3) + l];
			end
		end
	endgenerate
	genvar _gv_m_1;
	generate
		for (_gv_m_1 = 0; _gv_m_1 < 7; _gv_m_1 = _gv_m_1 + 1) begin : genblk5
			localparam m = _gv_m_1;
			assign couts[(m + 1) * 4] = couts8[m];
		end
	endgenerate
	assign sum = (a ^ b) ^ couts;
endmodule
module DividerUnsignedPipelined (
	clk,
	rst,
	stall,
	i_dividend,
	i_divisor,
	o_remainder,
	o_quotient
);
	input wire clk;
	input wire rst;
	input wire stall;
	input wire [31:0] i_dividend;
	input wire [31:0] i_divisor;
	output wire [31:0] o_remainder;
	output wire [31:0] o_quotient;
	reg [31:0] d_reg [0:8];
	reg [31:0] r_reg [0:8];
	reg [31:0] q_reg [0:8];
	reg [31:0] div_reg [0:8];
	wire [32:1] sv2v_tmp_9428F;
	assign sv2v_tmp_9428F = i_dividend;
	always @(*) d_reg[0] = sv2v_tmp_9428F;
	wire [32:1] sv2v_tmp_D0726;
	assign sv2v_tmp_D0726 = i_divisor;
	always @(*) div_reg[0] = sv2v_tmp_D0726;
	wire [32:1] sv2v_tmp_15998;
	assign sv2v_tmp_15998 = 32'b00000000000000000000000000000000;
	always @(*) r_reg[0] = sv2v_tmp_15998;
	wire [32:1] sv2v_tmp_952DB;
	assign sv2v_tmp_952DB = 32'b00000000000000000000000000000000;
	always @(*) q_reg[0] = sv2v_tmp_952DB;
	genvar _gv_i_3;
	generate
		for (_gv_i_3 = 0; _gv_i_3 < 8; _gv_i_3 = _gv_i_3 + 1) begin : genblk1
			localparam i = _gv_i_3;
			wire [31:0] d_tmp [0:4];
			wire [31:0] r_tmp [0:4];
			wire [31:0] q_tmp [0:4];
			assign d_tmp[0] = d_reg[i];
			assign r_tmp[0] = r_reg[i];
			assign q_tmp[0] = q_reg[i];
			genvar _gv_j_3;
			for (_gv_j_3 = 0; _gv_j_3 < 4; _gv_j_3 = _gv_j_3 + 1) begin : genblk1
				localparam j = _gv_j_3;
				divu_1iter doi(
					.i_dividend(d_tmp[j]),
					.i_divisor(div_reg[i]),
					.i_remainder(r_tmp[j]),
					.i_quotient(q_tmp[j]),
					.o_dividend(d_tmp[j + 1]),
					.o_remainder(r_tmp[j + 1]),
					.o_quotient(q_tmp[j + 1])
				);
			end
			if (i < 7) begin : gen_ff_stage
				always @(posedge clk)
					if (rst) begin
						d_reg[i + 1] <= 32'b00000000000000000000000000000000;
						r_reg[i + 1] <= 32'b00000000000000000000000000000000;
						q_reg[i + 1] <= 32'b00000000000000000000000000000000;
						div_reg[i + 1] <= 32'b00000000000000000000000000000000;
					end
					else begin
						d_reg[i + 1] <= d_tmp[4];
						r_reg[i + 1] <= r_tmp[4];
						q_reg[i + 1] <= q_tmp[4];
						div_reg[i + 1] <= div_reg[i];
					end
			end
			else begin : gen_output_stage
				assign o_remainder = r_tmp[4];
				assign o_quotient = q_tmp[4];
			end
		end
	endgenerate
endmodule
module divu_1iter (
	i_dividend,
	i_divisor,
	i_remainder,
	i_quotient,
	o_dividend,
	o_remainder,
	o_quotient
);
	reg _sv2v_0;
	input wire [31:0] i_dividend;
	input wire [31:0] i_divisor;
	input wire [31:0] i_remainder;
	input wire [31:0] i_quotient;
	output wire [31:0] o_dividend;
	output wire [31:0] o_remainder;
	output wire [31:0] o_quotient;
	reg [31:0] r;
	reg [31:0] q;
	always @(*) begin
		if (_sv2v_0)
			;
		r = (i_remainder << 1) | ((i_dividend >> 31) & 32'b00000000000000000000000000000001);
		q = i_quotient << 1;
		if (r >= i_divisor) begin
			q = q | 32'b00000000000000000000000000000001;
			r = r - i_divisor;
		end
	end
	assign o_dividend = i_dividend << 1;
	assign o_remainder = r;
	assign o_quotient = q;
	initial _sv2v_0 = 0;
endmodule
module Disasm (
	insn,
	disasm
);
	parameter signed [7:0] PREFIX = "D";
	input wire [31:0] insn;
	output wire [255:0] disasm;
endmodule
module RegFile (
	rd,
	rd_data,
	rs1,
	rs1_data,
	rs2,
	rs2_data,
	clk,
	we,
	rst
);
	input wire [4:0] rd;
	input wire [31:0] rd_data;
	input wire [4:0] rs1;
	output wire [31:0] rs1_data;
	input wire [4:0] rs2;
	output wire [31:0] rs2_data;
	input wire clk;
	input wire we;
	input wire rst;
	localparam signed [31:0] NumRegs = 32;
	reg [31:0] regs [0:31];
	wire [32:1] sv2v_tmp_A2C07;
	assign sv2v_tmp_A2C07 = 32'b00000000000000000000000000000000;
	always @(*) regs[0] = sv2v_tmp_A2C07;
	assign rs1_data = regs[rs1];
	assign rs2_data = regs[rs2];
	always @(posedge clk)
		if (rst) begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 1; i < NumRegs; i = i + 1)
				regs[i] <= 32'b00000000000000000000000000000000;
		end
		else if (we && (rd != 0))
			regs[rd] <= rd_data;
endmodule
module DatapathPipelined (
	clk,
	rst,
	pc_to_imem,
	insn_from_imem,
	addr_to_dmem,
	load_data_from_dmem,
	store_data_to_dmem,
	store_we_to_dmem,
	halt,
	trace_completed_pc,
	trace_completed_insn,
	trace_completed_cycle_status
);
	reg _sv2v_0;
	input wire clk;
	input wire rst;
	output wire [31:0] pc_to_imem;
	input wire [31:0] insn_from_imem;
	output reg [31:0] addr_to_dmem;
	input wire [31:0] load_data_from_dmem;
	output reg [31:0] store_data_to_dmem;
	output reg [3:0] store_we_to_dmem;
	output wire halt;
	output wire [31:0] trace_completed_pc;
	output wire [31:0] trace_completed_insn;
	output wire [31:0] trace_completed_cycle_status;
	localparam [6:0] OpLoad = 7'b0000011;
	localparam [6:0] OpStore = 7'b0100011;
	localparam [6:0] OpBranch = 7'b1100011;
	localparam [6:0] OpJalr = 7'b1100111;
	localparam [6:0] OpMiscMem = 7'b0001111;
	localparam [6:0] OpJal = 7'b1101111;
	localparam [6:0] OpRegImm = 7'b0010011;
	localparam [6:0] OpRegReg = 7'b0110011;
	localparam [6:0] OpEnviron = 7'b1110011;
	localparam [6:0] OpAuipc = 7'b0010111;
	localparam [6:0] OpLui = 7'b0110111;
	reg [31:0] cycles_current;
	always @(posedge clk)
		if (rst)
			cycles_current <= 0;
		else
			cycles_current <= cycles_current + 1;
	reg [31:0] f_pc_current;
	reg [31:0] f_pc_next;
	wire [31:0] f_insn;
	reg [31:0] f_cycle_status;
	always @(posedge clk)
		if (rst) begin
			f_pc_current <= 32'd0;
			f_cycle_status <= 32'd1;
		end
		else begin
			f_cycle_status <= 32'd1;
			f_pc_current <= f_pc_next;
		end
	assign pc_to_imem = f_pc_current;
	assign f_insn = insn_from_imem;
	wire [255:0] f_disasm;
	Disasm #(.PREFIX("F")) disasm_0fetch(
		.insn(f_insn),
		.disasm(f_disasm)
	);
	wire branch_taken;
	reg load_use_stall;
	reg div_stall;
	wire x_stall;
	wire d_stall;
	reg [95:0] decode_state;
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	always @(posedge clk)
		if (rst)
			decode_state <= 96'h000000000000000000000004;
		else if (branch_taken)
			decode_state <= 96'h000000000000000000000008;
		else if (d_stall)
			decode_state <= {sv2v_cast_32(decode_state[95-:32]), sv2v_cast_32(decode_state[63-:32]), sv2v_cast_32(decode_state[31-:32])};
		else
			decode_state <= {f_pc_current, f_insn, f_cycle_status};
	wire [255:0] d_disasm;
	Disasm #(.PREFIX("D")) disasm_1decode(
		.insn(decode_state[63-:32]),
		.disasm(d_disasm)
	);
	reg we;
	wire [4:0] rd;
	wire [31:0] rd_data;
	wire [4:0] rs1;
	wire [4:0] rs2;
	wire [31:0] rs1_data;
	wire [31:0] rs2_data;
	RegFile rf(
		.clk(clk),
		.rst(rst),
		.we(we),
		.rd(rd),
		.rd_data(rd_data),
		.rs1(rs1),
		.rs2(rs2),
		.rs1_data(rs1_data),
		.rs2_data(rs2_data)
	);
	wire [6:0] d_opcode;
	wire [4:0] insn_rs1;
	wire [4:0] insn_rs2;
	wire [4:0] insn_rd;
	assign d_opcode = decode_state[38:32];
	assign insn_rd = decode_state[43:39];
	assign insn_rs1 = decode_state[51:47];
	assign insn_rs2 = decode_state[56:52];
	reg use_rs1;
	reg use_rs2;
	always @(*) begin
		if (_sv2v_0)
			;
		case (d_opcode)
			OpRegImm, OpLoad, OpJalr: begin
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
	assign rs1 = (use_rs1 ? insn_rs1 : 5'b00000);
	assign rs2 = (use_rs2 ? insn_rs2 : 5'b00000);
	reg [31:0] d_rs1_data;
	reg [31:0] d_rs2_data;
	reg [31:0] wd_rs1_data;
	reg [31:0] wd_rs2_data;
	reg wd_bypass_taken;
	always @(*) begin
		if (_sv2v_0)
			;
		if (branch_taken) begin
			d_rs1_data = 32'b00000000000000000000000000000000;
			d_rs2_data = 32'b00000000000000000000000000000000;
		end
		else if (wd_bypass_taken) begin
			d_rs1_data = wd_rs1_data;
			d_rs2_data = wd_rs2_data;
		end
		else begin
			d_rs1_data = rs1_data;
			d_rs2_data = rs2_data;
		end
	end
	reg [31:0] d_pc;
	reg [31:0] d_insn;
	reg [31:0] d_cycle_status;
	reg [4:0] d_rd;
	reg [4:0] d_rs1;
	reg [4:0] d_rs2;
	always @(*) begin
		if (_sv2v_0)
			;
		d_pc = decode_state[95-:32];
		d_insn = decode_state[63-:32];
		d_cycle_status = decode_state[31-:32];
		d_rd = insn_rd;
		d_rs1 = insn_rs1;
		d_rs2 = insn_rs2;
		if ((branch_taken || load_use_stall) || div_stall) begin
			d_pc = 32'b00000000000000000000000000000000;
			d_insn = 32'h00000000;
			d_cycle_status = (branch_taken ? 32'd8 : (load_use_stall ? 32'd16 : 32'd2));
			d_rd = 5'b00000;
			d_rs1 = 5'b00000;
			d_rs2 = 5'b00000;
		end
	end
	reg [174:0] execute_state;
	always @(posedge clk)
		if (rst)
			execute_state <= 175'h00000000000000000000000200000000000000000000;
		else if (x_stall)
			execute_state <= execute_state;
		else
			execute_state <= {d_pc, d_insn, d_cycle_status, d_rd, d_rs1, d_rs2, d_rs1_data, d_rs2_data};
	wire [255:0] x_disasm;
	Disasm #(.PREFIX("X")) disasm_2execute(
		.insn(execute_state[142-:32]),
		.disasm(x_disasm)
	);
	wire [6:0] insn_funct7;
	wire [2:0] insn_funct3;
	wire [6:0] insn_opcode;
	assign insn_opcode = execute_state[117:111];
	assign insn_funct3 = execute_state[125:123];
	assign insn_funct7 = execute_state[142:136];
	wire [11:0] imm_i;
	assign imm_i = execute_state[142:131];
	wire [4:0] imm_shamt = execute_state[135:131];
	wire [11:0] imm_s;
	assign imm_s[11:5] = insn_funct7;
	assign imm_s[4:0] = execute_state[78-:5];
	wire [12:0] imm_b;
	assign {imm_b[12], imm_b[10:5]} = insn_funct7;
	assign {imm_b[4:1], imm_b[11]} = execute_state[78-:5];
	assign imm_b[0] = 1'b0;
	wire [20:0] imm_j;
	assign {imm_j[20], imm_j[10:1], imm_j[11], imm_j[19:12], imm_j[0]} = {execute_state[142:123], 1'b0};
	wire [19:0] imm_u;
	assign imm_u = execute_state[142:123];
	wire [31:0] imm_i_sext = {{20 {imm_i[11]}}, imm_i[11:0]};
	wire [31:0] imm_s_sext = {{20 {imm_s[11]}}, imm_s[11:0]};
	wire [31:0] imm_b_sext = {{19 {imm_b[12]}}, imm_b[12:0]};
	wire [31:0] imm_j_sext = {{11 {imm_j[20]}}, imm_j[20:0]};
	wire insn_lui = insn_opcode == OpLui;
	wire insn_auipc = insn_opcode == OpAuipc;
	wire insn_jal = insn_opcode == OpJal;
	wire insn_jalr = insn_opcode == OpJalr;
	wire insn_beq = (insn_opcode == OpBranch) && (execute_state[125:123] == 3'b000);
	wire insn_bne = (insn_opcode == OpBranch) && (execute_state[125:123] == 3'b001);
	wire insn_blt = (insn_opcode == OpBranch) && (execute_state[125:123] == 3'b100);
	wire insn_bge = (insn_opcode == OpBranch) && (execute_state[125:123] == 3'b101);
	wire insn_bltu = (insn_opcode == OpBranch) && (execute_state[125:123] == 3'b110);
	wire insn_bgeu = (insn_opcode == OpBranch) && (execute_state[125:123] == 3'b111);
	wire insn_addi = (insn_opcode == OpRegImm) && (execute_state[125:123] == 3'b000);
	wire insn_slti = (insn_opcode == OpRegImm) && (execute_state[125:123] == 3'b010);
	wire insn_sltiu = (insn_opcode == OpRegImm) && (execute_state[125:123] == 3'b011);
	wire insn_xori = (insn_opcode == OpRegImm) && (execute_state[125:123] == 3'b100);
	wire insn_ori = (insn_opcode == OpRegImm) && (execute_state[125:123] == 3'b110);
	wire insn_andi = (insn_opcode == OpRegImm) && (execute_state[125:123] == 3'b111);
	wire insn_slli = ((insn_opcode == OpRegImm) && (execute_state[125:123] == 3'b001)) && (execute_state[142:136] == 7'd0);
	wire insn_srli = ((insn_opcode == OpRegImm) && (execute_state[125:123] == 3'b101)) && (execute_state[142:136] == 7'd0);
	wire insn_srai = ((insn_opcode == OpRegImm) && (execute_state[125:123] == 3'b101)) && (execute_state[142:136] == 7'b0100000);
	wire insn_add = ((insn_opcode == OpRegReg) && (execute_state[125:123] == 3'b000)) && (execute_state[142:136] == 7'd0);
	wire insn_sub = ((insn_opcode == OpRegReg) && (execute_state[125:123] == 3'b000)) && (execute_state[142:136] == 7'b0100000);
	wire insn_sll = ((insn_opcode == OpRegReg) && (execute_state[125:123] == 3'b001)) && (execute_state[142:136] == 7'd0);
	wire insn_slt = ((insn_opcode == OpRegReg) && (execute_state[125:123] == 3'b010)) && (execute_state[142:136] == 7'd0);
	wire insn_sltu = ((insn_opcode == OpRegReg) && (execute_state[125:123] == 3'b011)) && (execute_state[142:136] == 7'd0);
	wire insn_xor = ((insn_opcode == OpRegReg) && (execute_state[125:123] == 3'b100)) && (execute_state[142:136] == 7'd0);
	wire insn_srl = ((insn_opcode == OpRegReg) && (execute_state[125:123] == 3'b101)) && (execute_state[142:136] == 7'd0);
	wire insn_sra = ((insn_opcode == OpRegReg) && (execute_state[125:123] == 3'b101)) && (execute_state[142:136] == 7'b0100000);
	wire insn_or = ((insn_opcode == OpRegReg) && (execute_state[125:123] == 3'b110)) && (execute_state[142:136] == 7'd0);
	wire insn_and = ((insn_opcode == OpRegReg) && (execute_state[125:123] == 3'b111)) && (execute_state[142:136] == 7'd0);
	wire insn_mul = ((insn_opcode == OpRegReg) && (execute_state[142:136] == 7'd1)) && (execute_state[125:123] == 3'b000);
	wire insn_mulh = ((insn_opcode == OpRegReg) && (execute_state[142:136] == 7'd1)) && (execute_state[125:123] == 3'b001);
	wire insn_mulhsu = ((insn_opcode == OpRegReg) && (execute_state[142:136] == 7'd1)) && (execute_state[125:123] == 3'b010);
	wire insn_mulhu = ((insn_opcode == OpRegReg) && (execute_state[142:136] == 7'd1)) && (execute_state[125:123] == 3'b011);
	wire insn_div = ((insn_opcode == OpRegReg) && (execute_state[142:136] == 7'd1)) && (execute_state[125:123] == 3'b100);
	wire insn_divu = ((insn_opcode == OpRegReg) && (execute_state[142:136] == 7'd1)) && (execute_state[125:123] == 3'b101);
	wire insn_rem = ((insn_opcode == OpRegReg) && (execute_state[142:136] == 7'd1)) && (execute_state[125:123] == 3'b110);
	wire insn_remu = ((insn_opcode == OpRegReg) && (execute_state[142:136] == 7'd1)) && (execute_state[125:123] == 3'b111);
	wire insn_ecall = (insn_opcode == OpEnviron) && (execute_state[142:118] == 25'd0);
	wire insn_fence = insn_opcode == OpMiscMem;
	reg [31:0] alu_a;
	reg [31:0] alu_b;
	wire [31:0] alu_sum;
	reg alu_cin;
	CarryLookaheadAdder alu_cla(
		.a(alu_a),
		.b(alu_b),
		.cin(alu_cin),
		.sum(alu_sum)
	);
	reg [31:0] bypassed_rs1_data;
	reg [31:0] bypassed_rs2_data;
	always @(*) begin
		if (_sv2v_0)
			;
		case (insn_opcode)
			OpJal: alu_a = execute_state[174-:32];
			OpLui: alu_a = 32'b00000000000000000000000000000000;
			default: alu_a = bypassed_rs1_data;
		endcase
		case (insn_opcode)
			OpRegImm, OpLoad, OpJalr: alu_b = imm_i_sext;
			OpStore: alu_b = imm_s_sext;
			OpLui: alu_b = imm_u << 12;
			OpJal: alu_b = 32'd4;
			OpRegReg:
				if (insn_sub)
					alu_b = ~bypassed_rs2_data;
				else
					alu_b = bypassed_rs2_data;
			default: alu_b = bypassed_rs2_data;
		endcase
	end
	reg [31:0] div_dividend;
	reg [31:0] div_divisor;
	wire [31:0] div_quotient_raw;
	wire [31:0] div_remainder_raw;
	DividerUnsignedPipelined divider(
		.clk(clk),
		.rst(rst),
		.stall(1'b0),
		.i_dividend(div_dividend),
		.i_divisor(div_divisor),
		.o_remainder(div_remainder_raw),
		.o_quotient(div_quotient_raw)
	);
	wire insn_uses_divider = ((insn_div || insn_divu) || insn_rem) || insn_remu;
	wire is_signed_div;
	assign is_signed_div = insn_div || insn_rem;
	reg div_by_zero;
	reg div_overflow;
	reg want_neg_quotient;
	reg want_neg_remainder;
	always @(*) begin
		if (_sv2v_0)
			;
		div_by_zero = alu_b == 32'b00000000000000000000000000000000;
		div_overflow = (is_signed_div && (alu_a == 32'h80000000)) && (alu_b == 32'hffffffff);
		if (is_signed_div) begin
			div_dividend = (alu_a[31] ? ~alu_a + 32'd1 : alu_a);
			div_divisor = (alu_b[31] ? ~alu_b + 32'd1 : alu_b);
			want_neg_quotient = ((alu_a[31] != alu_b[31]) && !div_by_zero) && !div_overflow;
			want_neg_remainder = alu_a[31];
		end
		else begin
			div_dividend = alu_a;
			div_divisor = alu_b;
			want_neg_quotient = 1'b0;
			want_neg_remainder = 1'b0;
		end
	end
	reg [972:0] div_sr;
	wire div_in_flight = (((((div_sr[138] || div_sr[277]) || div_sr[416]) || div_sr[555]) || div_sr[694]) || div_sr[833]) || div_sr[972];
	reg x_halt;
	function automatic [4:0] sv2v_cast_5;
		input reg [4:0] inp;
		sv2v_cast_5 = inp;
	endfunction
	always @(posedge clk)
		if (rst) begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < 7; i = i + 1)
				div_sr[i * 139+:139] <= 139'h00000000000000000000000008000000000;
		end
		else begin
			begin : sv2v_autoblock_2
				reg signed [31:0] i;
				for (i = 1; i < 7; i = i + 1)
					div_sr[i * 139+:139] <= div_sr[(i - 1) * 139+:139];
			end
			if ((execute_state[110-:32] == 32'd1) && insn_uses_divider)
				div_sr[0+:139] <= {1'b1, sv2v_cast_5(execute_state[78-:5]), sv2v_cast_32(execute_state[174-:32]), sv2v_cast_32(execute_state[142-:32]), sv2v_cast_32(execute_state[110-:32]), x_halt, div_by_zero, div_overflow, want_neg_quotient, want_neg_remainder, bypassed_rs1_data};
			else
				div_sr[0+:139] <= 139'h00000000000000000000000002000000000;
		end
	wire [63:0] mul_res_signed;
	wire [63:0] mul_res_unsigned;
	wire [63:0] mul_res_su;
	assign mul_res_signed = $signed(alu_a) * $signed(alu_b);
	assign mul_res_unsigned = alu_a * alu_b;
	assign mul_res_su = $signed(alu_a) * $signed({1'b0, alu_b});
	reg illegal_insn;
	reg [31:0] x_output_data;
	reg [31:0] x_rs2_data;
	reg x_branch_taken;
	always @(*) begin
		if (_sv2v_0)
			;
		illegal_insn = 1'b0;
		alu_cin = 1'b0;
		x_halt = 1'b0;
		f_pc_next = (d_stall ? f_pc_current : f_pc_current + 32'd4);
		x_output_data = 32'b00000000000000000000000000000000;
		x_rs2_data = execute_state[31-:32];
		x_branch_taken = 1'b0;
		case (insn_opcode)
			OpLui: x_output_data = imm_u << 12;
			OpAuipc: x_output_data = execute_state[174-:32] + (imm_u << 12);
			OpRegImm:
				if (insn_addi)
					x_output_data = alu_sum;
				else if (insn_slti)
					x_output_data = ($signed(alu_a) < $signed(imm_i_sext) ? 32'd1 : 32'd0);
				else if (insn_sltiu)
					x_output_data = (alu_a < imm_i_sext ? 32'd1 : 32'd0);
				else if (insn_xori)
					x_output_data = alu_a ^ imm_i_sext;
				else if (insn_ori)
					x_output_data = alu_a | imm_i_sext;
				else if (insn_andi)
					x_output_data = alu_a & imm_i_sext;
				else if (insn_slli)
					x_output_data = alu_a << imm_shamt;
				else if (insn_srli)
					x_output_data = alu_a >> imm_shamt;
				else if (insn_srai)
					x_output_data = $signed(alu_a) >>> imm_shamt;
				else
					illegal_insn = 1'b1;
			OpRegReg:
				if (insn_mul)
					x_output_data = mul_res_signed[31:0];
				else if (insn_mulh)
					x_output_data = mul_res_signed[63:32];
				else if (insn_mulhsu)
					x_output_data = mul_res_su[63:32];
				else if (insn_mulhu)
					x_output_data = mul_res_unsigned[63:32];
				else if (insn_add)
					x_output_data = alu_sum;
				else if (insn_sub) begin
					alu_cin = 1'b1;
					x_output_data = alu_sum;
				end
				else if (insn_sll)
					x_output_data = alu_a << alu_b[4:0];
				else if (insn_slt)
					x_output_data = ($signed(alu_a) < $signed(alu_b) ? 32'd1 : 32'd0);
				else if (insn_sltu)
					x_output_data = (alu_a < alu_b ? 32'd1 : 32'd0);
				else if (insn_xor)
					x_output_data = alu_a ^ alu_b;
				else if (insn_srl)
					x_output_data = alu_a >> alu_b[4:0];
				else if (insn_sra)
					x_output_data = $signed(alu_a) >>> alu_b[4:0];
				else if (insn_or)
					x_output_data = alu_a | alu_b;
				else if (insn_and)
					x_output_data = alu_a & alu_b;
				else
					illegal_insn = 1'b1;
			OpStore, OpLoad: begin
				x_output_data = alu_a + alu_b;
				x_rs2_data = bypassed_rs2_data;
			end
			OpJal: begin
				x_branch_taken = 1'b1;
				x_output_data = execute_state[174-:32] + 32'd4;
				f_pc_next = execute_state[174-:32] + $signed(imm_j_sext);
			end
			OpJalr: begin
				x_branch_taken = 1'b1;
				x_output_data = execute_state[174-:32] + 32'd4;
				f_pc_next = (alu_a + $signed(imm_i_sext)) & ~32'b00000000000000000000000000000001;
			end
			OpBranch:
				if (insn_beq) begin
					if (alu_a == alu_b) begin
						x_branch_taken = 1'b1;
						f_pc_next = execute_state[174-:32] + imm_b_sext;
					end
				end
				else if (insn_bne) begin
					if (alu_a != alu_b) begin
						x_branch_taken = 1'b1;
						f_pc_next = execute_state[174-:32] + imm_b_sext;
					end
				end
				else if (insn_blt) begin
					if ($signed(alu_a) < $signed(alu_b)) begin
						x_branch_taken = 1'b1;
						f_pc_next = execute_state[174-:32] + imm_b_sext;
					end
				end
				else if (insn_bge) begin
					if ($signed(alu_a) >= $signed(alu_b)) begin
						x_branch_taken = 1'b1;
						f_pc_next = execute_state[174-:32] + imm_b_sext;
					end
				end
				else if (insn_bltu) begin
					if (alu_a < alu_b) begin
						x_branch_taken = 1'b1;
						f_pc_next = execute_state[174-:32] + imm_b_sext;
					end
				end
				else if (insn_bgeu) begin
					if (alu_a >= alu_b) begin
						x_branch_taken = 1'b1;
						f_pc_next = execute_state[174-:32] + imm_b_sext;
					end
				end
				else
					illegal_insn = 1'b1;
			OpEnviron:
				if (insn_ecall)
					x_halt = 1'b1;
				else
					illegal_insn = 1'b1;
			default: illegal_insn = 1'b1;
		endcase
	end
	assign branch_taken = x_branch_taken;
	wire dependent_d_rs1 = use_rs1 && (execute_state[78-:5] == insn_rs1);
	wire dependent_d_rs2 = use_rs2 && (execute_state[78-:5] == insn_rs2);
	always @(*) begin
		if (_sv2v_0)
			;
		load_use_stall = 0;
		if ((execute_state[78-:5] != 0) && (insn_opcode == OpLoad)) begin
			if (dependent_d_rs1 || (dependent_d_rs2 && (d_opcode != OpStore)))
				load_use_stall = 1'b1;
		end
	end
	always @(*) begin
		if (_sv2v_0)
			;
		div_stall = 0;
		if ((execute_state[78-:5] != 0) && insn_uses_divider) begin
			if (dependent_d_rs1 || dependent_d_rs2)
				div_stall = 1'b1;
		end
		begin : sv2v_autoblock_3
			reg signed [31:0] i;
			for (i = 0; i < 6; i = i + 1)
				if (div_sr[(i * 139) + 138] && (div_sr[(i * 139) + 137-:5] != 0)) begin
					if ((use_rs1 && (insn_rs1 == div_sr[(i * 139) + 137-:5])) || (use_rs2 && (insn_rs2 == div_sr[(i * 139) + 137-:5])))
						div_stall = 1'b1;
				end
		end
	end
	assign x_stall = ((execute_state[110-:32] == 32'd1) && !insn_uses_divider) && div_in_flight;
	assign d_stall = (load_use_stall || div_stall) || x_stall;
	reg [170:0] m_next;
	reg [31:0] div_out;
	always @(*) begin
		if (_sv2v_0)
			;
		if (div_sr[972])
			m_next = {sv2v_cast_32(div_sr[966-:32]), sv2v_cast_32(div_sr[934-:32]), div_sr[870], sv2v_cast_32(div_sr[902-:32]), sv2v_cast_5(div_sr[971-:5]), 5'b00000, div_out, 32'b00000000000000000000000000000000};
		else if (div_in_flight || ((execute_state[110-:32] == 32'd1) && insn_uses_divider))
			m_next = 171'h0000000000000000000000008000000000000000000;
		else
			m_next = {sv2v_cast_32(execute_state[174-:32]), sv2v_cast_32(execute_state[142-:32]), x_halt, sv2v_cast_32(execute_state[110-:32]), sv2v_cast_5(execute_state[78-:5]), sv2v_cast_5(execute_state[68-:5]), x_output_data, x_rs2_data};
	end
	reg [170:0] memory_state;
	always @(posedge clk)
		if (rst)
			memory_state <= 171'h0000000000000000000000010000000000000000000;
		else
			memory_state <= m_next;
	wire [255:0] m_disasm;
	Disasm #(.PREFIX("M")) disasm_3memory(
		.insn(memory_state[138-:32]),
		.disasm(m_disasm)
	);
	wire [6:0] m_insn_opcode = memory_state[113:107];
	wire insn_lb = (m_insn_opcode == OpLoad) && (memory_state[121:119] == 3'b000);
	wire insn_lh = (m_insn_opcode == OpLoad) && (memory_state[121:119] == 3'b001);
	wire insn_lw = (m_insn_opcode == OpLoad) && (memory_state[121:119] == 3'b010);
	wire insn_lbu = (m_insn_opcode == OpLoad) && (memory_state[121:119] == 3'b100);
	wire insn_lhu = (m_insn_opcode == OpLoad) && (memory_state[121:119] == 3'b101);
	wire insn_sb = (m_insn_opcode == OpStore) && (memory_state[121:119] == 3'b000);
	wire insn_sh = (m_insn_opcode == OpStore) && (memory_state[121:119] == 3'b001);
	wire insn_sw = (m_insn_opcode == OpStore) && (memory_state[121:119] == 3'b010);
	reg [31:0] full_addr_to_dmem;
	reg [7:0] byte_val_dmem;
	reg [15:0] half_val_dmem;
	reg [31:0] m_load_data;
	reg [31:0] m_rs2_data;
	reg wm_bypass_taken;
	reg [31:0] wm_rs2_data;
	always @(*) begin
		if (_sv2v_0)
			;
		m_load_data = 32'b00000000000000000000000000000000;
		m_rs2_data = memory_state[31-:32];
		if (wm_bypass_taken)
			m_rs2_data = wm_rs2_data;
		addr_to_dmem = 32'b00000000000000000000000000000000;
		store_we_to_dmem = 4'b0000;
		store_data_to_dmem = 32'b00000000000000000000000000000000;
		case (m_insn_opcode)
			OpLoad: begin
				full_addr_to_dmem = memory_state[63-:32];
				addr_to_dmem = {full_addr_to_dmem[31:2], 2'b00};
				case (full_addr_to_dmem[1:0])
					2'b00: byte_val_dmem = load_data_from_dmem[7:0];
					2'b01: byte_val_dmem = load_data_from_dmem[15:8];
					2'b10: byte_val_dmem = load_data_from_dmem[23:16];
					2'b11: byte_val_dmem = load_data_from_dmem[31:24];
				endcase
				if (full_addr_to_dmem[1])
					half_val_dmem = load_data_from_dmem[31:16];
				else
					half_val_dmem = load_data_from_dmem[15:0];
				if (insn_lb)
					m_load_data = {{24 {byte_val_dmem[7]}}, byte_val_dmem};
				else if (insn_lh)
					m_load_data = {{16 {half_val_dmem[15]}}, half_val_dmem};
				else if (insn_lw)
					m_load_data = load_data_from_dmem;
				else if (insn_lbu)
					m_load_data = {24'b000000000000000000000000, byte_val_dmem};
				else if (insn_lhu)
					m_load_data = {16'b0000000000000000, half_val_dmem};
			end
			OpStore: begin
				full_addr_to_dmem = memory_state[63-:32];
				addr_to_dmem = {full_addr_to_dmem[31:2], 2'b00};
				if (insn_sb) begin
					case (full_addr_to_dmem[1:0])
						2'b00: store_we_to_dmem = 4'b0001;
						2'b01: store_we_to_dmem = 4'b0010;
						2'b10: store_we_to_dmem = 4'b0100;
						2'b11: store_we_to_dmem = 4'b1000;
					endcase
					store_data_to_dmem = {4 {m_rs2_data[7:0]}};
				end
				else if (insn_sh) begin
					if (full_addr_to_dmem[1])
						store_we_to_dmem = 4'b1100;
					else
						store_we_to_dmem = 4'b0011;
					store_data_to_dmem = {2 {m_rs2_data[15:0]}};
				end
				else if (insn_sw) begin
					store_we_to_dmem = 4'b1111;
					store_data_to_dmem = m_rs2_data;
				end
			end
			default:
				;
		endcase
	end
	wire [6:0] div_out_funct7 = div_sr[934-:7];
	wire [2:0] div_out_funct3 = div_sr[917-:3];
	wire div_out_insn_div = (div_out_funct7 == 7'd1) && (div_out_funct3 == 3'b100);
	wire div_out_insn_divu = (div_out_funct7 == 7'd1) && (div_out_funct3 == 3'b101);
	wire div_out_insn_rem = (div_out_funct7 == 7'd1) && (div_out_funct3 == 3'b110);
	wire div_out_insn_remu = (div_out_funct7 == 7'd1) && (div_out_funct3 == 3'b111);
	always @(*) begin
		if (_sv2v_0)
			;
		div_out = 32'd0;
		if (div_sr[972]) begin
			if (div_out_insn_div) begin
				if (div_sr[869])
					div_out = 32'hffffffff;
				else if (div_sr[868])
					div_out = 32'h80000000;
				else
					div_out = (div_sr[867] ? ~div_quotient_raw + 32'd1 : div_quotient_raw);
			end
			else if (div_out_insn_divu) begin
				if (div_sr[869])
					div_out = 32'hffffffff;
				else
					div_out = div_quotient_raw;
			end
			else if (div_out_insn_rem) begin
				if (div_sr[869])
					div_out = div_sr[865-:32];
				else if (div_sr[868])
					div_out = 32'h00000000;
				else
					div_out = (div_sr[866] ? ~div_remainder_raw + 32'd1 : div_remainder_raw);
			end
			else if (div_out_insn_remu) begin
				if (div_sr[869])
					div_out = div_sr[865-:32];
				else
					div_out = div_remainder_raw;
			end
		end
	end
	reg [165:0] writeback_state;
	always @(posedge clk)
		if (rst)
			writeback_state <= 166'h000000000000000000000000800000000000000000;
		else
			writeback_state <= {sv2v_cast_32(memory_state[170-:32]), sv2v_cast_32(memory_state[138-:32]), memory_state[106], sv2v_cast_32(memory_state[105-:32]), sv2v_cast_5(memory_state[73-:5]), sv2v_cast_32(memory_state[63-:32]), m_load_data};
	wire [255:0] w_disasm;
	Disasm #(.PREFIX("W")) disasm_4writeback(
		.insn(writeback_state[133-:32]),
		.disasm(w_disasm)
	);
	reg [31:0] w_rd_data;
	wire [6:0] w_insn_opcode = writeback_state[108:102];
	assign rd = writeback_state[68-:5];
	assign halt = writeback_state[101];
	always @(*) begin
		if (_sv2v_0)
			;
		we = 1'b0;
		w_rd_data = writeback_state[63-:32];
		if (writeback_state[100-:32] == 32'd1) begin
			we = 1'b1;
			case (w_insn_opcode)
				OpLoad: w_rd_data = writeback_state[31-:32];
				OpStore, OpBranch, OpEnviron: we = 1'b0;
				default:
					;
			endcase
		end
	end
	wire can_mx_bypass = (((memory_state[73-:5] != 0) && (m_insn_opcode != OpLoad)) && (m_insn_opcode != OpStore)) && (m_insn_opcode != OpBranch);
	always @(*) begin
		if (_sv2v_0)
			;
		if (can_mx_bypass && (memory_state[73-:5] == execute_state[73-:5]))
			bypassed_rs1_data = memory_state[63-:32];
		else if ((we && (writeback_state[68-:5] != 0)) && (writeback_state[68-:5] == execute_state[73-:5]))
			bypassed_rs1_data = w_rd_data;
		else
			bypassed_rs1_data = execute_state[63-:32];
		if (can_mx_bypass && (memory_state[73-:5] == execute_state[68-:5]))
			bypassed_rs2_data = memory_state[63-:32];
		else if ((we && (writeback_state[68-:5] != 0)) && (writeback_state[68-:5] == execute_state[68-:5]))
			bypassed_rs2_data = w_rd_data;
		else
			bypassed_rs2_data = execute_state[31-:32];
	end
	always @(*) begin
		if (_sv2v_0)
			;
		wd_bypass_taken = 1'b0;
		wd_rs1_data = rs1_data;
		wd_rs2_data = rs2_data;
		if ((writeback_state[68-:5] != 0) && we) begin
			if (writeback_state[68-:5] == d_rs1) begin
				wd_bypass_taken = 1'b1;
				wd_rs1_data = w_rd_data;
			end
			if (writeback_state[68-:5] == d_rs2) begin
				wd_bypass_taken = 1'b1;
				wd_rs2_data = w_rd_data;
			end
		end
	end
	wire wm_dep = ((w_insn_opcode == OpLoad) && (m_insn_opcode == OpStore)) && (writeback_state[68-:5] == memory_state[68-:5]);
	always @(*) begin
		if (_sv2v_0)
			;
		wm_bypass_taken = 1'b0;
		wm_rs2_data = memory_state[31-:32];
		if ((writeback_state[68-:5] != 0) && we) begin
			if (wm_dep) begin
				wm_bypass_taken = 1'b1;
				wm_rs2_data = w_rd_data;
			end
		end
	end
	assign rd_data = w_rd_data;
	assign trace_completed_pc = writeback_state[165-:32];
	assign trace_completed_insn = writeback_state[133-:32];
	assign trace_completed_cycle_status = writeback_state[100-:32];
	initial _sv2v_0 = 0;
endmodule
module MemorySingleCycle (
	rst,
	clk,
	pc_to_imem,
	insn_from_imem,
	addr_to_dmem,
	load_data_from_dmem,
	store_data_to_dmem,
	store_we_to_dmem
);
	reg _sv2v_0;
	parameter signed [31:0] NUM_WORDS = 512;
	input wire rst;
	input wire clk;
	input wire [31:0] pc_to_imem;
	output reg [31:0] insn_from_imem;
	input wire [31:0] addr_to_dmem;
	output reg [31:0] load_data_from_dmem;
	input wire [31:0] store_data_to_dmem;
	input wire [3:0] store_we_to_dmem;
	reg [31:0] mem_array [0:NUM_WORDS - 1];
	initial $readmemh("mem_initial_contents.hex", mem_array);
	always @(*)
		if (_sv2v_0)
			;
	localparam signed [31:0] AddrMsb = $clog2(NUM_WORDS) + 1;
	localparam signed [31:0] AddrLsb = 2;
	always @(negedge clk)
		if (rst)
			;
		else
			insn_from_imem <= mem_array[{pc_to_imem[AddrMsb:AddrLsb]}];
	always @(negedge clk)
		if (rst)
			;
		else begin
			if (store_we_to_dmem[0])
				mem_array[addr_to_dmem[AddrMsb:AddrLsb]][7:0] <= store_data_to_dmem[7:0];
			if (store_we_to_dmem[1])
				mem_array[addr_to_dmem[AddrMsb:AddrLsb]][15:8] <= store_data_to_dmem[15:8];
			if (store_we_to_dmem[2])
				mem_array[addr_to_dmem[AddrMsb:AddrLsb]][23:16] <= store_data_to_dmem[23:16];
			if (store_we_to_dmem[3])
				mem_array[addr_to_dmem[AddrMsb:AddrLsb]][31:24] <= store_data_to_dmem[31:24];
			load_data_from_dmem <= mem_array[{addr_to_dmem[AddrMsb:AddrLsb]}];
		end
	initial _sv2v_0 = 0;
endmodule
module SystemResourceCheck (
	external_clk_25MHz,
	btn,
	led
);
	input wire external_clk_25MHz;
	input wire [6:0] btn;
	output wire [7:0] led;
	wire clk_proc;
	wire clk_locked;
	MyClockGen clock_gen(
		.input_clk_25MHz(external_clk_25MHz),
		.clk_proc(clk_proc),
		.locked(clk_locked)
	);
	wire [31:0] pc_to_imem;
	wire [31:0] insn_from_imem;
	wire [31:0] mem_data_addr;
	wire [31:0] mem_data_loaded_value;
	wire [31:0] mem_data_to_write;
	wire [3:0] mem_data_we;
	wire [31:0] trace_writeback_pc;
	wire [31:0] trace_writeback_insn;
	wire [31:0] trace_writeback_cycle_status;
	MemorySingleCycle #(.NUM_WORDS(128)) memory(
		.rst(!clk_locked),
		.clk(clk_proc),
		.pc_to_imem(pc_to_imem),
		.insn_from_imem(insn_from_imem),
		.addr_to_dmem(mem_data_addr),
		.load_data_from_dmem(mem_data_loaded_value),
		.store_data_to_dmem(mem_data_to_write),
		.store_we_to_dmem(mem_data_we)
	);
	DatapathPipelined datapath(
		.clk(clk_proc),
		.rst(!clk_locked),
		.pc_to_imem(pc_to_imem),
		.insn_from_imem(insn_from_imem),
		.addr_to_dmem(mem_data_addr),
		.store_data_to_dmem(mem_data_to_write),
		.store_we_to_dmem(mem_data_we),
		.load_data_from_dmem(mem_data_loaded_value),
		.halt(led[0]),
		.trace_completed_pc(trace_writeback_pc),
		.trace_completed_insn(trace_writeback_insn),
		.trace_completed_cycle_status(trace_writeback_cycle_status)
	);
endmodule