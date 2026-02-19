module MyClockGen (
	input_clk_25MHz,
	clk_proc,
	clk_mem,
	locked
);
	input input_clk_25MHz;
	output wire clk_proc;
	output wire clk_mem;
	output wire locked;
	wire clkfb;
	(* FREQUENCY_PIN_CLKI = "25" *) (* FREQUENCY_PIN_CLKOP = "4.16667" *) (* FREQUENCY_PIN_CLKOS = "4.01003" *) (* ICP_CURRENT = "12" *) (* LPF_RESISTOR = "8" *) (* MFG_ENABLE_FILTEROPAMP = "1" *) (* MFG_GMCREF_SEL = "2" *) EHXPLLL #(
		.PLLRST_ENA("DISABLED"),
		.INTFB_WAKE("DISABLED"),
		.STDBY_ENABLE("DISABLED"),
		.DPHASE_SOURCE("DISABLED"),
		.OUTDIVIDER_MUXA("DIVA"),
		.OUTDIVIDER_MUXB("DIVB"),
		.OUTDIVIDER_MUXC("DIVC"),
		.OUTDIVIDER_MUXD("DIVD"),
		.CLKI_DIV(6),
		.CLKOP_ENABLE("ENABLED"),
		.CLKOP_DIV(128),
		.CLKOP_CPHASE(64),
		.CLKOP_FPHASE(0),
		.CLKOS_ENABLE("ENABLED"),
		.CLKOS_DIV(133),
		.CLKOS_CPHASE(97),
		.CLKOS_FPHASE(2),
		.FEEDBK_PATH("INT_OP"),
		.CLKFB_DIV(1)
	) pll_i(
		.RST(1'b0),
		.STDBY(1'b0),
		.CLKI(input_clk_25MHz),
		.CLKOP(clk_proc),
		.CLKOS(clk_mem),
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
module DividerUnsigned (
	i_dividend,
	i_divisor,
	o_remainder,
	o_quotient
);
	input wire [31:0] i_dividend;
	input wire [31:0] i_divisor;
	output wire [31:0] o_remainder;
	output wire [31:0] o_quotient;
	wire [31:0] d [0:32];
	wire [31:0] r [0:32];
	wire [31:0] q [0:32];
	assign d[0] = i_dividend;
	assign r[0] = 32'b00000000000000000000000000000000;
	assign q[0] = 32'b00000000000000000000000000000000;
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 < 32; _gv_i_1 = _gv_i_1 + 1) begin : genblk1
			localparam i = _gv_i_1;
			DividerOneIter doi(
				.i_dividend(d[i]),
				.i_divisor(i_divisor),
				.i_remainder(r[i]),
				.i_quotient(q[i]),
				.o_dividend(d[i + 1]),
				.o_remainder(r[i + 1]),
				.o_quotient(q[i + 1])
			);
		end
	endgenerate
	assign o_remainder = r[32];
	assign o_quotient = q[32];
endmodule
module DividerOneIter (
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
	genvar _gv_i_2;
	wire [N - 1:0] tmp_out;
	generate
		for (_gv_i_2 = 0; _gv_i_2 < (N - 1); _gv_i_2 = _gv_i_2 + 1) begin : genblk1
			localparam i = _gv_i_2;
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
	genvar _gv_i_3;
	wire [31:0] g;
	wire [31:0] p;
	generate
		for (_gv_i_3 = 0; _gv_i_3 < 32; _gv_i_3 = _gv_i_3 + 1) begin : genblk1
			localparam i = _gv_i_3;
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
module DatapathSingleCycle (
	clk,
	rst,
	halt,
	pc_to_imem,
	insn_from_imem,
	addr_to_dmem,
	load_data_from_dmem,
	store_data_to_dmem,
	store_we_to_dmem,
	trace_completed_pc,
	trace_completed_insn,
	trace_completed_cycle_status
);
	reg _sv2v_0;
	input wire clk;
	input wire rst;
	output reg halt;
	output wire [31:0] pc_to_imem;
	input wire [31:0] insn_from_imem;
	output reg [31:0] addr_to_dmem;
	input wire [31:0] load_data_from_dmem;
	output reg [31:0] store_data_to_dmem;
	output reg [3:0] store_we_to_dmem;
	output wire [31:0] trace_completed_pc;
	output wire [31:0] trace_completed_insn;
	output wire [31:0] trace_completed_cycle_status;
	wire [6:0] insn_funct7;
	wire [4:0] insn_rs2;
	wire [4:0] insn_rs1;
	wire [2:0] insn_funct3;
	wire [4:0] insn_rd;
	wire [6:0] insn_opcode;
	assign {insn_funct7, insn_rs2, insn_rs1, insn_funct3, insn_rd, insn_opcode} = insn_from_imem;
	wire [11:0] imm_i;
	assign imm_i = insn_from_imem[31:20];
	wire [4:0] imm_shamt = insn_from_imem[24:20];
	wire [11:0] imm_s;
	assign imm_s[11:5] = insn_funct7;
	assign imm_s[4:0] = insn_rd;
	wire [12:0] imm_b;
	assign {imm_b[12], imm_b[10:5]} = insn_funct7;
	assign {imm_b[4:1], imm_b[11]} = insn_rd;
	assign imm_b[0] = 1'b0;
	wire [20:0] imm_j;
	assign {imm_j[20], imm_j[10:1], imm_j[11], imm_j[19:12], imm_j[0]} = {insn_from_imem[31:12], 1'b0};
	wire [19:0] imm_u;
	assign imm_u = insn_from_imem[31:12];
	wire [31:0] imm_i_sext = {{20 {imm_i[11]}}, imm_i[11:0]};
	wire [31:0] imm_s_sext = {{20 {imm_s[11]}}, imm_s[11:0]};
	wire [31:0] imm_b_sext = {{19 {imm_b[12]}}, imm_b[12:0]};
	wire [31:0] imm_j_sext = {{11 {imm_j[20]}}, imm_j[20:0]};
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
	wire insn_lui = insn_opcode == OpLui;
	wire insn_auipc = insn_opcode == OpAuipc;
	wire insn_jal = insn_opcode == OpJal;
	wire insn_jalr = insn_opcode == OpJalr;
	wire insn_beq = (insn_opcode == OpBranch) && (insn_from_imem[14:12] == 3'b000);
	wire insn_bne = (insn_opcode == OpBranch) && (insn_from_imem[14:12] == 3'b001);
	wire insn_blt = (insn_opcode == OpBranch) && (insn_from_imem[14:12] == 3'b100);
	wire insn_bge = (insn_opcode == OpBranch) && (insn_from_imem[14:12] == 3'b101);
	wire insn_bltu = (insn_opcode == OpBranch) && (insn_from_imem[14:12] == 3'b110);
	wire insn_bgeu = (insn_opcode == OpBranch) && (insn_from_imem[14:12] == 3'b111);
	wire insn_lb = (insn_opcode == OpLoad) && (insn_from_imem[14:12] == 3'b000);
	wire insn_lh = (insn_opcode == OpLoad) && (insn_from_imem[14:12] == 3'b001);
	wire insn_lw = (insn_opcode == OpLoad) && (insn_from_imem[14:12] == 3'b010);
	wire insn_lbu = (insn_opcode == OpLoad) && (insn_from_imem[14:12] == 3'b100);
	wire insn_lhu = (insn_opcode == OpLoad) && (insn_from_imem[14:12] == 3'b101);
	wire insn_sb = (insn_opcode == OpStore) && (insn_from_imem[14:12] == 3'b000);
	wire insn_sh = (insn_opcode == OpStore) && (insn_from_imem[14:12] == 3'b001);
	wire insn_sw = (insn_opcode == OpStore) && (insn_from_imem[14:12] == 3'b010);
	wire insn_addi = (insn_opcode == OpRegImm) && (insn_from_imem[14:12] == 3'b000);
	wire insn_slti = (insn_opcode == OpRegImm) && (insn_from_imem[14:12] == 3'b010);
	wire insn_sltiu = (insn_opcode == OpRegImm) && (insn_from_imem[14:12] == 3'b011);
	wire insn_xori = (insn_opcode == OpRegImm) && (insn_from_imem[14:12] == 3'b100);
	wire insn_ori = (insn_opcode == OpRegImm) && (insn_from_imem[14:12] == 3'b110);
	wire insn_andi = (insn_opcode == OpRegImm) && (insn_from_imem[14:12] == 3'b111);
	wire insn_slli = ((insn_opcode == OpRegImm) && (insn_from_imem[14:12] == 3'b001)) && (insn_from_imem[31:25] == 7'd0);
	wire insn_srli = ((insn_opcode == OpRegImm) && (insn_from_imem[14:12] == 3'b101)) && (insn_from_imem[31:25] == 7'd0);
	wire insn_srai = ((insn_opcode == OpRegImm) && (insn_from_imem[14:12] == 3'b101)) && (insn_from_imem[31:25] == 7'b0100000);
	wire insn_add = ((insn_opcode == OpRegReg) && (insn_from_imem[14:12] == 3'b000)) && (insn_from_imem[31:25] == 7'd0);
	wire insn_sub = ((insn_opcode == OpRegReg) && (insn_from_imem[14:12] == 3'b000)) && (insn_from_imem[31:25] == 7'b0100000);
	wire insn_sll = ((insn_opcode == OpRegReg) && (insn_from_imem[14:12] == 3'b001)) && (insn_from_imem[31:25] == 7'd0);
	wire insn_slt = ((insn_opcode == OpRegReg) && (insn_from_imem[14:12] == 3'b010)) && (insn_from_imem[31:25] == 7'd0);
	wire insn_sltu = ((insn_opcode == OpRegReg) && (insn_from_imem[14:12] == 3'b011)) && (insn_from_imem[31:25] == 7'd0);
	wire insn_xor = ((insn_opcode == OpRegReg) && (insn_from_imem[14:12] == 3'b100)) && (insn_from_imem[31:25] == 7'd0);
	wire insn_srl = ((insn_opcode == OpRegReg) && (insn_from_imem[14:12] == 3'b101)) && (insn_from_imem[31:25] == 7'd0);
	wire insn_sra = ((insn_opcode == OpRegReg) && (insn_from_imem[14:12] == 3'b101)) && (insn_from_imem[31:25] == 7'b0100000);
	wire insn_or = ((insn_opcode == OpRegReg) && (insn_from_imem[14:12] == 3'b110)) && (insn_from_imem[31:25] == 7'd0);
	wire insn_and = ((insn_opcode == OpRegReg) && (insn_from_imem[14:12] == 3'b111)) && (insn_from_imem[31:25] == 7'd0);
	wire insn_mul = ((insn_opcode == OpRegReg) && (insn_from_imem[31:25] == 7'd1)) && (insn_from_imem[14:12] == 3'b000);
	wire insn_mulh = ((insn_opcode == OpRegReg) && (insn_from_imem[31:25] == 7'd1)) && (insn_from_imem[14:12] == 3'b001);
	wire insn_mulhsu = ((insn_opcode == OpRegReg) && (insn_from_imem[31:25] == 7'd1)) && (insn_from_imem[14:12] == 3'b010);
	wire insn_mulhu = ((insn_opcode == OpRegReg) && (insn_from_imem[31:25] == 7'd1)) && (insn_from_imem[14:12] == 3'b011);
	wire insn_div = ((insn_opcode == OpRegReg) && (insn_from_imem[31:25] == 7'd1)) && (insn_from_imem[14:12] == 3'b100);
	wire insn_divu = ((insn_opcode == OpRegReg) && (insn_from_imem[31:25] == 7'd1)) && (insn_from_imem[14:12] == 3'b101);
	wire insn_rem = ((insn_opcode == OpRegReg) && (insn_from_imem[31:25] == 7'd1)) && (insn_from_imem[14:12] == 3'b110);
	wire insn_remu = ((insn_opcode == OpRegReg) && (insn_from_imem[31:25] == 7'd1)) && (insn_from_imem[14:12] == 3'b111);
	wire insn_ecall = (insn_opcode == OpEnviron) && (insn_from_imem[31:7] == 25'd0);
	wire insn_fence = insn_opcode == OpMiscMem;
	reg [31:0] pcNext;
	reg [31:0] pcCurrent;
	always @(posedge clk)
		if (rst)
			pcCurrent <= 32'd0;
		else
			pcCurrent <= pcNext;
	assign pc_to_imem = pcCurrent;
	reg [31:0] cycles_current;
	reg [31:0] num_insns_current;
	always @(posedge clk)
		if (rst) begin
			cycles_current <= 0;
			num_insns_current <= 0;
		end
		else begin
			cycles_current <= cycles_current + 1;
			if (!rst)
				num_insns_current <= num_insns_current + 1;
		end
	reg we;
	reg [4:0] rd;
	reg [31:0] rd_data;
	reg [4:0] rs1;
	reg [4:0] rs2;
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
	wire is_m_extension;
	assign is_m_extension = (insn_opcode == 7'b0110011) && (insn_funct7 == 7'b0000001);
	wire [63:0] mul_res_signed;
	wire [63:0] mul_res_unsigned;
	wire [63:0] mul_res_su;
	assign mul_res_signed = $signed(rs1_data) * $signed(rs2_data);
	assign mul_res_unsigned = rs1_data * rs2_data;
	assign mul_res_su = $signed(rs1_data) * $signed({1'b0, rs2_data});
	wire is_div_signed;
	assign is_div_signed = ~insn_funct3[0];
	wire [31:0] div_abs_a;
	wire [31:0] div_abs_b;
	assign div_abs_a = (is_div_signed && rs1_data[31] ? ~rs1_data + 32'd1 : rs1_data);
	assign div_abs_b = (is_div_signed && rs2_data[31] ? ~rs2_data + 32'd1 : rs2_data);
	wire [31:0] div_quotient_raw;
	wire [31:0] div_remainder_raw;
	DividerUnsigned divider_inst(
		.i_dividend(div_abs_a),
		.i_divisor(div_abs_b),
		.o_quotient(div_quotient_raw),
		.o_remainder(div_remainder_raw)
	);
	wire want_neg_quotient;
	wire want_neg_remainder;
	assign want_neg_quotient = is_div_signed && (rs1_data[31] ^ rs2_data[31]);
	assign want_neg_remainder = is_div_signed && rs1_data[31];
	wire div_by_zero;
	wire div_overflow;
	assign div_by_zero = rs2_data == 0;
	assign div_overflow = ((rs1_data == 32'h80000000) && (rs2_data == 32'hffffffff)) && is_div_signed;
	reg [31:0] full_addr_to_dmem;
	reg [7:0] byte_val_dmem;
	reg [15:0] half_val_dmem;
	reg illegal_insn;
	always @(*) begin
		if (_sv2v_0)
			;
		illegal_insn = 1'b0;
		we = 1'b0;
		rd = 5'b00000;
		rd_data = 32'b00000000000000000000000000000000;
		rs1 = 5'b00000;
		rs2 = 5'b00000;
		alu_a = 32'b00000000000000000000000000000000;
		alu_b = 32'b00000000000000000000000000000000;
		alu_cin = 1'b0;
		halt = 1'b0;
		pcNext = pcCurrent + 32'd4;
		full_addr_to_dmem = 32'b00000000000000000000000000000000;
		byte_val_dmem = 8'b00000000;
		half_val_dmem = 16'b0000000000000000;
		addr_to_dmem = 32'b00000000000000000000000000000000;
		store_data_to_dmem = 32'b00000000000000000000000000000000;
		store_we_to_dmem = 4'b0000;
		case (insn_opcode)
			OpLui: begin
				we = 1'b1;
				rd = insn_rd;
				rd_data = imm_u << 12;
			end
			OpAuipc: begin
				we = 1'b1;
				rd = insn_rd;
				rd_data = pcCurrent + (imm_u << 12);
			end
			OpRegImm: begin
				we = 1'b1;
				rd = insn_rd;
				rs1 = insn_rs1;
				if (insn_addi) begin
					alu_a = rs1_data;
					alu_b = imm_i_sext;
					rd_data = alu_sum;
				end
				else if (insn_slti)
					rd_data = ($signed(rs1_data) < $signed(imm_i_sext) ? 32'd1 : 32'd0);
				else if (insn_sltiu)
					rd_data = (rs1_data < imm_i_sext ? 32'd1 : 32'd0);
				else if (insn_xori)
					rd_data = rs1_data ^ imm_i_sext;
				else if (insn_ori)
					rd_data = rs1_data | imm_i_sext;
				else if (insn_andi)
					rd_data = rs1_data & imm_i_sext;
				else if (insn_slli)
					rd_data = rs1_data << imm_shamt;
				else if (insn_srli)
					rd_data = rs1_data >> imm_shamt;
				else if (insn_srai)
					rd_data = $signed(rs1_data) >>> imm_shamt;
				else
					illegal_insn = 1'b1;
			end
			OpRegReg: begin
				we = 1'b1;
				rd = insn_rd;
				rs1 = insn_rs1;
				rs2 = insn_rs2;
				if (insn_mul)
					rd_data = mul_res_signed[31:0];
				else if (insn_mulh)
					rd_data = mul_res_signed[63:32];
				else if (insn_mulhsu)
					rd_data = mul_res_su[63:32];
				else if (insn_mulhu)
					rd_data = mul_res_unsigned[63:32];
				else if (insn_div) begin
					if (div_by_zero)
						rd_data = 32'hffffffff;
					else if (div_overflow)
						rd_data = 32'h80000000;
					else
						rd_data = (want_neg_quotient ? ~div_quotient_raw + 32'd1 : div_quotient_raw);
				end
				else if (insn_divu) begin
					if (div_by_zero)
						rd_data = 32'hffffffff;
					else
						rd_data = div_quotient_raw;
				end
				else if (insn_rem) begin
					if (div_by_zero)
						rd_data = rs1_data;
					else if (div_overflow)
						rd_data = 32'h00000000;
					else
						rd_data = (want_neg_remainder ? ~div_remainder_raw + 32'd1 : div_remainder_raw);
				end
				else if (insn_remu) begin
					if (div_by_zero)
						rd_data = rs1_data;
					else
						rd_data = div_remainder_raw;
				end
				else if (insn_add) begin
					alu_a = rs1_data;
					alu_b = rs2_data;
					rd_data = alu_sum;
				end
				else if (insn_sub) begin
					alu_a = rs1_data;
					alu_b = ~rs2_data;
					alu_cin = 1'b1;
					rd_data = alu_sum;
				end
				else if (insn_sll)
					rd_data = rs1_data << rs2_data[4:0];
				else if (insn_slt)
					rd_data = ($signed(rs1_data) < $signed(rs2_data) ? 32'd1 : 32'd0);
				else if (insn_sltu)
					rd_data = (rs1_data < rs2_data ? 32'd1 : 32'd0);
				else if (insn_xor)
					rd_data = rs1_data ^ rs2_data;
				else if (insn_srl)
					rd_data = rs1_data >> rs2_data[4:0];
				else if (insn_sra)
					rd_data = $signed(rs1_data) >>> rs2_data[4:0];
				else if (insn_or)
					rd_data = rs1_data | rs2_data;
				else if (insn_and)
					rd_data = rs1_data & rs2_data;
				else
					illegal_insn = 1'b1;
			end
			OpJal: begin
				we = 1'b1;
				rd = insn_rd;
				rd_data = pcCurrent + 32'd4;
				pcNext = pcCurrent + $signed(imm_j_sext);
			end
			OpJalr: begin
				we = 1'b1;
				rd = insn_rd;
				rs1 = insn_rs1;
				rd_data = pcCurrent + 32'd4;
				pcNext = (rs1_data + $signed(imm_i_sext)) & ~32'b00000000000000000000000000000001;
			end
			OpLoad: begin
				we = 1'b1;
				rd = insn_rd;
				rs1 = insn_rs1;
				full_addr_to_dmem = rs1_data + imm_i_sext;
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
					rd_data = {{24 {byte_val_dmem[7]}}, byte_val_dmem};
				else if (insn_lh)
					rd_data = {{16 {half_val_dmem[15]}}, half_val_dmem};
				else if (insn_lw)
					rd_data = load_data_from_dmem;
				else if (insn_lbu)
					rd_data = {24'b000000000000000000000000, byte_val_dmem};
				else if (insn_lhu)
					rd_data = {16'b0000000000000000, half_val_dmem};
				else
					illegal_insn = 1'b1;
			end
			OpStore: begin
				rs1 = insn_rs1;
				rs2 = insn_rs2;
				full_addr_to_dmem = rs1_data + imm_s_sext;
				addr_to_dmem = {full_addr_to_dmem[31:2], 2'b00};
				if (insn_sb) begin
					case (full_addr_to_dmem[1:0])
						2'b00: store_we_to_dmem = 4'b0001;
						2'b01: store_we_to_dmem = 4'b0010;
						2'b10: store_we_to_dmem = 4'b0100;
						2'b11: store_we_to_dmem = 4'b1000;
					endcase
					store_data_to_dmem = {4 {rs2_data[7:0]}};
				end
				else if (insn_sh) begin
					if (full_addr_to_dmem[1])
						store_we_to_dmem = 4'b1100;
					else
						store_we_to_dmem = 4'b0011;
					store_data_to_dmem = {2 {rs2_data[15:0]}};
				end
				else if (insn_sw) begin
					store_we_to_dmem = 4'b1111;
					store_data_to_dmem = rs2_data;
				end
				else
					illegal_insn = 1'b1;
			end
			OpBranch: begin
				rs1 = insn_rs1;
				rs2 = insn_rs2;
				if (insn_beq) begin
					if (rs1_data == rs2_data)
						pcNext = pcCurrent + imm_b_sext;
				end
				else if (insn_bne) begin
					if (rs1_data != rs2_data)
						pcNext = pcCurrent + imm_b_sext;
				end
				else if (insn_blt) begin
					if ($signed(rs1_data) < $signed(rs2_data))
						pcNext = pcCurrent + imm_b_sext;
				end
				else if (insn_bge) begin
					if ($signed(rs1_data) >= $signed(rs2_data))
						pcNext = pcCurrent + imm_b_sext;
				end
				else if (insn_bltu) begin
					if (rs1_data < rs2_data)
						pcNext = pcCurrent + imm_b_sext;
				end
				else if (insn_bgeu) begin
					if (rs1_data >= rs2_data)
						pcNext = pcCurrent + imm_b_sext;
				end
				else
					illegal_insn = 1'b1;
			end
			OpEnviron:
				if (insn_ecall)
					halt = 1'b1;
				else
					illegal_insn = 1'b1;
			default: illegal_insn = 1'b1;
		endcase
	end
	assign trace_completed_pc = pcCurrent;
	assign trace_completed_insn = insn_from_imem;
	assign trace_completed_cycle_status = 32'd1;
	initial _sv2v_0 = 0;
endmodule
module MemorySingleCycle (
	rst,
	clock_mem,
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
	input wire clock_mem;
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
	always @(posedge clock_mem)
		if (rst)
			;
		else
			insn_from_imem <= mem_array[{pc_to_imem[AddrMsb:AddrLsb]}];
	always @(negedge clock_mem)
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
`default_nettype none
module SystemResourceCheck (
	external_clk_25MHz,
	btn,
	led
);
	input wire external_clk_25MHz;
	input wire [6:0] btn;
	output wire [7:0] led;
	wire clk_proc;
	wire clk_mem;
	wire clk_locked;
	MyClockGen clock_gen(
		.input_clk_25MHz(external_clk_25MHz),
		.clk_proc(clk_proc),
		.clk_mem(clk_mem),
		.locked(clk_locked)
	);
	wire [31:0] pc_to_imem;
	wire [31:0] insn_from_imem;
	wire [31:0] mem_data_addr;
	wire [31:0] mem_data_loaded_value;
	wire [31:0] mem_data_to_write;
	wire [3:0] mem_data_we;
	MemorySingleCycle #(.NUM_WORDS(128)) memory(
		.rst(!clk_locked),
		.clock_mem(clk_mem),
		.pc_to_imem(pc_to_imem),
		.insn_from_imem(insn_from_imem),
		.addr_to_dmem(mem_data_addr),
		.load_data_from_dmem(mem_data_loaded_value),
		.store_data_to_dmem(mem_data_to_write),
		.store_we_to_dmem(mem_data_we)
	);
	DatapathSingleCycle datapath(
		.clk(clk_proc),
		.rst(!clk_locked),
		.pc_to_imem(pc_to_imem),
		.insn_from_imem(insn_from_imem),
		.addr_to_dmem(mem_data_addr),
		.store_data_to_dmem(mem_data_to_write),
		.store_we_to_dmem(mem_data_we),
		.load_data_from_dmem(mem_data_loaded_value),
		.halt(led[0])
	);
endmodule