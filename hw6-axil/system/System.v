`default_nettype none
module MyClockGen (
	input_clk_25MHz,
	clk_125MHz,
	clk_25MHz,
	clk_proc,
	locked
);
	input input_clk_25MHz;
	output wire clk_125MHz;
	output wire clk_25MHz;
	output wire clk_proc;
	output wire locked;
	wire clkfb;
	(* FREQUENCY_PIN_CLKI = "25" *) (* FREQUENCY_PIN_CLKOP = "125" *) (* FREQUENCY_PIN_CLKOS = "25" *) (* FREQUENCY_PIN_CLKOS2 = "20.1613" *) (* ICP_CURRENT = "12" *) (* LPF_RESISTOR = "8" *) (* MFG_ENABLE_FILTEROPAMP = "1" *) (* MFG_GMCREF_SEL = "2" *) EHXPLLL #(
		.PLLRST_ENA("DISABLED"),
		.INTFB_WAKE("DISABLED"),
		.STDBY_ENABLE("DISABLED"),
		.DPHASE_SOURCE("DISABLED"),
		.OUTDIVIDER_MUXA("DIVA"),
		.OUTDIVIDER_MUXB("DIVB"),
		.OUTDIVIDER_MUXC("DIVC"),
		.OUTDIVIDER_MUXD("DIVD"),
		.CLKI_DIV(1),
		.CLKOP_ENABLE("ENABLED"),
		.CLKOP_DIV(5),
		.CLKOP_CPHASE(2),
		.CLKOP_FPHASE(0),
		.CLKOS_ENABLE("ENABLED"),
		.CLKOS_DIV(25),
		.CLKOS_CPHASE(2),
		.CLKOS_FPHASE(0),
		.CLKOS2_ENABLE("ENABLED"),
		.CLKOS2_DIV(31),
		.CLKOS2_CPHASE(2),
		.CLKOS2_FPHASE(0),
		.FEEDBK_PATH("INT_OP"),
		.CLKFB_DIV(5)
	) pll_i(
		.RST(1'b0),
		.STDBY(1'b0),
		.CLKI(input_clk_25MHz),
		.CLKOP(clk_125MHz),
		.CLKOS(clk_25MHz),
		.CLKOS2(clk_proc),
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
`default_nettype none
`default_nettype none
module skidbuffer (
	i_clk,
	i_reset,
	i_valid,
	o_ready,
	i_data,
	o_valid,
	i_ready,
	o_data
);
	parameter [0:0] OPT_LOWPOWER = 0;
	parameter [0:0] OPT_OUTREG = 1;
	parameter [0:0] OPT_PASSTHROUGH = 0;
	parameter DW = 8;
	parameter [0:0] OPT_INITIAL = 1'b1;
	input wire i_clk;
	input wire i_reset;
	input wire i_valid;
	output wire o_ready;
	input wire [DW - 1:0] i_data;
	output wire o_valid;
	input wire i_ready;
	output reg [DW - 1:0] o_data;
	wire [DW - 1:0] w_data;
	generate
		if (OPT_PASSTHROUGH) begin : PASSTHROUGH
			assign {o_valid, o_ready} = {i_valid, i_ready};
			always @(*)
				if (!i_valid && OPT_LOWPOWER)
					o_data = 0;
				else
					o_data = i_data;
			assign w_data = 0;
			wire unused_passthrough;
			assign unused_passthrough = &{1'b0, i_clk, i_reset};
		end
		else begin : LOGIC
			reg r_valid;
			reg [DW - 1:0] r_data;
			initial if (OPT_INITIAL)
				r_valid = 0;
			always @(posedge i_clk)
				if (i_reset)
					r_valid <= 0;
				else if ((i_valid && o_ready) && (o_valid && !i_ready))
					r_valid <= 1;
				else if (i_ready)
					r_valid <= 0;
			initial if (OPT_INITIAL)
				r_data = 0;
			always @(posedge i_clk)
				if (OPT_LOWPOWER && i_reset)
					r_data <= 0;
				else if (OPT_LOWPOWER && (!o_valid || i_ready))
					r_data <= 0;
				else if (((!OPT_LOWPOWER || !OPT_OUTREG) || i_valid) && o_ready)
					r_data <= i_data;
			assign w_data = r_data;
			assign o_ready = !r_valid;
			if (!OPT_OUTREG) begin : NET_OUTPUT
				assign o_valid = !i_reset && (i_valid || r_valid);
				always @(*)
					if (r_valid)
						o_data = r_data;
					else if (!OPT_LOWPOWER || i_valid)
						o_data = i_data;
					else
						o_data = 0;
			end
			else begin : REG_OUTPUT
				reg ro_valid;
				initial if (OPT_INITIAL)
					ro_valid = 0;
				always @(posedge i_clk)
					if (i_reset)
						ro_valid <= 0;
					else if (!o_valid || i_ready)
						ro_valid <= i_valid || r_valid;
				assign o_valid = ro_valid;
				initial if (OPT_INITIAL)
					o_data = 0;
				always @(posedge i_clk)
					if (OPT_LOWPOWER && i_reset)
						o_data <= 0;
					else if (!o_valid || i_ready) begin
						if (r_valid)
							o_data <= r_data;
						else if (!OPT_LOWPOWER || i_valid)
							o_data <= i_data;
						else
							o_data <= 0;
					end
			end
		end
	endgenerate
	wire unused;
	assign unused = &{1'b0, w_data};
endmodule
module Disasm (
	insn,
	disasm
);
	parameter PREFIX = "D";
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
`default_nettype none
module SystemResourceCheck (
	external_clk_25MHz,
	btn,
	led
);
	input wire external_clk_25MHz;
	input wire [6:0] btn;
	output wire [7:0] led;
	wire clk;
	wire clk_locked;
	wire ignore0;
	wire ignore1;
	MyClockGen clock_gen(
		.input_clk_25MHz(external_clk_25MHz),
		.clk_125MHz(ignore0),
		.clk_25MHz(ignore1),
		.clk_proc(clk),
		.locked(clk_locked)
	);
	wire rst = !clk_locked;
	generate
		if (1) begin : axil_mem_ro
			localparam signed [31:0] ADDR_WIDTH = 32;
			localparam signed [31:0] DATA_WIDTH = 32;
			wire ARREADY;
			reg ARVALID;
			wire [31:0] ARADDR;
			wire [2:0] ARPROT;
			wire RREADY;
			wire RVALID;
			wire [31:0] RDATA;
			wire [1:0] RRESP;
			wire AWREADY;
			wire AWVALID;
			wire [31:0] AWADDR;
			wire [2:0] AWPROT;
			wire WREADY;
			wire WVALID;
			wire [31:0] WDATA;
			wire [3:0] WSTRB;
			wire BREADY;
			wire BVALID;
			wire [1:0] BRESP;
		end
		if (1) begin : axil_mem_rw
			localparam signed [31:0] ADDR_WIDTH = 32;
			localparam signed [31:0] DATA_WIDTH = 32;
			wire ARREADY;
			reg ARVALID;
			reg [31:0] ARADDR;
			wire [2:0] ARPROT;
			wire RREADY;
			wire RVALID;
			wire [31:0] RDATA;
			wire [1:0] RRESP;
			wire AWREADY;
			reg AWVALID;
			reg [31:0] AWADDR;
			wire [2:0] AWPROT;
			wire WREADY;
			reg WVALID;
			reg [31:0] WDATA;
			reg [3:0] WSTRB;
			wire BREADY;
			wire BVALID;
			wire [1:0] BRESP;
		end
	endgenerate
	localparam _param_F80E1_OPT_SKIDBUFFER = 1;
	localparam _param_F80E1_OPT_LOWPOWER = 0;
	localparam _param_F80E1_NUM_WORDS = 128;
	generate
		if (1) begin : memory
			localparam [0:0] OPT_SKIDBUFFER = _param_F80E1_OPT_SKIDBUFFER;
			localparam [0:0] OPT_LOWPOWER = _param_F80E1_OPT_LOWPOWER;
			localparam NUM_WORDS = _param_F80E1_NUM_WORDS;
			wire ACLK;
			wire ARESETn;
			localparam ADDRLSB = 2;
			wire i_reset = !ARESETn;
			wire axil_write_ready;
			wire [29:0] awskd_addr;
			wire [31:0] wskd_data;
			wire [3:0] wskd_strb;
			reg axil_bvalid;
			wire axil_read_ready;
			wire [29:0] arskd_addr;
			reg [31:0] axil_read_data;
			reg axil_read_valid;
			wire t_axil_read_ready;
			wire [29:0] t_arskd_addr;
			reg [31:0] t_axil_read_data;
			reg t_axil_read_valid;
			localparam signed [31:0] AddrLsb = 2;
			localparam signed [31:0] AddrMsb = 8;
			reg [31:0] mem_array [0:127];
			if (OPT_SKIDBUFFER) begin : SKIDBUFFER_WRITE
				wire awskd_valid;
				wire wskd_valid;
				skidbuffer #(
					.OPT_OUTREG(0),
					.OPT_LOWPOWER(OPT_LOWPOWER),
					.DW(30)
				) axilawskid(
					.i_clk(ACLK),
					.i_reset(i_reset),
					.i_valid(SystemResourceCheck.axil_mem_rw.AWVALID),
					.o_ready(SystemResourceCheck.axil_mem_rw.AWREADY),
					.i_data(SystemResourceCheck.axil_mem_rw.AWADDR[31:ADDRLSB]),
					.o_valid(awskd_valid),
					.i_ready(axil_write_ready),
					.o_data(awskd_addr)
				);
				skidbuffer #(
					.OPT_OUTREG(0),
					.OPT_LOWPOWER(OPT_LOWPOWER),
					.DW(36)
				) axilwskid(
					.i_clk(ACLK),
					.i_reset(i_reset),
					.i_valid(SystemResourceCheck.axil_mem_rw.WVALID),
					.o_ready(SystemResourceCheck.axil_mem_rw.WREADY),
					.i_data({SystemResourceCheck.axil_mem_rw.WDATA, SystemResourceCheck.axil_mem_rw.WSTRB}),
					.o_valid(wskd_valid),
					.i_ready(axil_write_ready),
					.o_data({wskd_data, wskd_strb})
				);
				assign axil_write_ready = (awskd_valid && wskd_valid) && (!SystemResourceCheck.axil_mem_rw.BVALID || SystemResourceCheck.axil_mem_rw.BREADY);
			end
			else begin : SIMPLE_WRITES
				reg axil_awready;
				initial axil_awready = 1'b0;
				always @(posedge ACLK)
					if (!ARESETn)
						axil_awready <= 1'b0;
					else
						axil_awready <= (!axil_awready && (SystemResourceCheck.axil_mem_rw.AWVALID && SystemResourceCheck.axil_mem_rw.WVALID)) && (!SystemResourceCheck.axil_mem_rw.BVALID || SystemResourceCheck.axil_mem_rw.BREADY);
				assign SystemResourceCheck.axil_mem_rw.AWREADY = axil_awready;
				assign SystemResourceCheck.axil_mem_rw.WREADY = axil_awready;
				assign awskd_addr = SystemResourceCheck.axil_mem_rw.AWADDR[31:ADDRLSB];
				assign wskd_data = SystemResourceCheck.axil_mem_rw.WDATA;
				assign wskd_strb = SystemResourceCheck.axil_mem_rw.WSTRB;
				assign axil_write_ready = axil_awready;
			end
			initial axil_bvalid = 0;
			always @(posedge ACLK)
				if (i_reset)
					axil_bvalid <= 0;
				else if (axil_write_ready)
					axil_bvalid <= 1;
				else if (SystemResourceCheck.axil_mem_rw.BREADY)
					axil_bvalid <= 0;
			assign SystemResourceCheck.axil_mem_rw.BVALID = axil_bvalid;
			assign SystemResourceCheck.axil_mem_rw.BRESP = 2'b00;
			if (OPT_SKIDBUFFER) begin : SKIDBUFFER_READ
				wire arskd_valid;
				skidbuffer #(
					.OPT_OUTREG(0),
					.OPT_LOWPOWER(OPT_LOWPOWER),
					.DW(30)
				) axilarskid(
					.i_clk(ACLK),
					.i_reset(i_reset),
					.i_valid(SystemResourceCheck.axil_mem_rw.ARVALID),
					.o_ready(SystemResourceCheck.axil_mem_rw.ARREADY),
					.i_data(SystemResourceCheck.axil_mem_rw.ARADDR[31:ADDRLSB]),
					.o_valid(arskd_valid),
					.i_ready(axil_read_ready),
					.o_data(arskd_addr)
				);
				assign axil_read_ready = arskd_valid && (!axil_read_valid || SystemResourceCheck.axil_mem_rw.RREADY);
			end
			else begin : SIMPLE_READS
				reg axil_arready;
				always @(*) axil_arready = !SystemResourceCheck.axil_mem_rw.RVALID;
				assign arskd_addr = SystemResourceCheck.axil_mem_rw.ARADDR[31:ADDRLSB];
				assign SystemResourceCheck.axil_mem_rw.ARREADY = axil_arready;
				assign axil_read_ready = SystemResourceCheck.axil_mem_rw.ARVALID && SystemResourceCheck.axil_mem_rw.ARREADY;
			end
			initial axil_read_valid = 1'b0;
			always @(posedge ACLK)
				if (i_reset)
					axil_read_valid <= 1'b0;
				else if (axil_read_ready)
					axil_read_valid <= 1'b1;
				else if (SystemResourceCheck.axil_mem_rw.RREADY)
					axil_read_valid <= 1'b0;
			assign SystemResourceCheck.axil_mem_rw.RVALID = axil_read_valid;
			assign SystemResourceCheck.axil_mem_rw.RDATA = axil_read_data;
			assign SystemResourceCheck.axil_mem_rw.RRESP = 2'b00;
			if (OPT_SKIDBUFFER) begin : T_SKIDBUFFER_READ
				wire t_arskd_valid;
				skidbuffer #(
					.OPT_OUTREG(0),
					.OPT_LOWPOWER(OPT_LOWPOWER),
					.DW(30)
				) axilarskid(
					.i_clk(ACLK),
					.i_reset(i_reset),
					.i_valid(SystemResourceCheck.axil_mem_ro.ARVALID),
					.o_ready(SystemResourceCheck.axil_mem_ro.ARREADY),
					.i_data(SystemResourceCheck.axil_mem_ro.ARADDR[31:ADDRLSB]),
					.o_valid(t_arskd_valid),
					.i_ready(t_axil_read_ready),
					.o_data(t_arskd_addr)
				);
				assign t_axil_read_ready = t_arskd_valid && (!t_axil_read_valid || SystemResourceCheck.axil_mem_ro.RREADY);
			end
			else begin : T_SIMPLE_READS
				reg t_axil_arready;
				always @(*) t_axil_arready = !SystemResourceCheck.axil_mem_ro.RVALID;
				assign t_arskd_addr = SystemResourceCheck.axil_mem_ro.ARADDR[31:ADDRLSB];
				assign SystemResourceCheck.axil_mem_ro.ARREADY = t_axil_arready;
				assign t_axil_read_ready = SystemResourceCheck.axil_mem_ro.ARVALID && SystemResourceCheck.axil_mem_ro.ARREADY;
			end
			initial t_axil_read_valid = 1'b0;
			always @(posedge ACLK)
				if (i_reset)
					t_axil_read_valid <= 1'b0;
				else if (t_axil_read_ready)
					t_axil_read_valid <= 1'b1;
				else if (SystemResourceCheck.axil_mem_ro.RREADY)
					t_axil_read_valid <= 1'b0;
			assign SystemResourceCheck.axil_mem_ro.RVALID = t_axil_read_valid;
			assign SystemResourceCheck.axil_mem_ro.RDATA = t_axil_read_data;
			assign SystemResourceCheck.axil_mem_ro.RRESP = 2'b00;
			always @(posedge ACLK)
				if (i_reset)
					;
				else if (axil_write_ready) begin
					if (wskd_strb[0])
						mem_array[awskd_addr[6:0]][7:0] <= wskd_data[7:0];
					if (wskd_strb[1])
						mem_array[awskd_addr[6:0]][15:8] <= wskd_data[15:8];
					if (wskd_strb[2])
						mem_array[awskd_addr[6:0]][23:16] <= wskd_data[23:16];
					if (wskd_strb[3])
						mem_array[awskd_addr[6:0]][31:24] <= wskd_data[31:24];
				end
			initial begin
				axil_read_data = 0;
				t_axil_read_data = 0;
			end
			always @(posedge ACLK) begin
				if (!SystemResourceCheck.axil_mem_rw.RVALID || SystemResourceCheck.axil_mem_rw.RREADY)
					axil_read_data <= mem_array[arskd_addr[6:0]];
				if (!SystemResourceCheck.axil_mem_ro.RVALID || SystemResourceCheck.axil_mem_ro.RREADY)
					t_axil_read_data <= mem_array[t_arskd_addr[6:0]];
			end
		end
	endgenerate
	assign memory.ACLK = clk;
	assign memory.ARESETn = ~rst;
	wire [31:0] trace_completed_pc;
	wire [31:0] trace_completed_insn;
	wire [31:0] trace_completed_cycle_status;
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	function automatic [4:0] sv2v_cast_5;
		input reg [4:0] inp;
		sv2v_cast_5 = inp;
	endfunction
	generate
		if (1) begin : datapath
			reg _sv2v_0;
			wire clk;
			wire rst;
			wire halt;
			wire [31:0] trace_completed_pc;
			wire [31:0] trace_completed_insn;
			wire [31:0] trace_completed_cycle_status;
			localparam [0:0] True = 1'b1;
			localparam [0:0] False = 1'b0;
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
			wire branch_taken;
			reg [31:0] f_pc_current;
			reg [31:0] f_pc_next;
			wire d_stall;
			always @(*) begin
				if (_sv2v_0)
					;
				SystemResourceCheck.axil_mem_ro.ARVALID = True;
				if (branch_taken || d_stall)
					SystemResourceCheck.axil_mem_ro.ARVALID = False;
			end
			assign SystemResourceCheck.axil_mem_ro.ARADDR = f_pc_current;
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
			wire [255:0] f_disasm;
			Disasm #(.PREFIX("F")) disasm_0fetch(
				.insn(0),
				.disasm(f_disasm)
			);
			reg [63:0] get_state;
			always @(posedge clk)
				if (rst)
					get_state <= 64'h0000000000000004;
				else if (branch_taken)
					get_state <= 64'h0000000000000008;
				else if (d_stall)
					get_state <= get_state;
				else
					get_state <= {f_pc_current, f_cycle_status};
			reg [31:0] g_insn;
			wire g_valid = SystemResourceCheck.axil_mem_ro.RVALID;
			wire g_stall = !g_valid;
			assign SystemResourceCheck.axil_mem_ro.RREADY = !d_stall;
			always @(*) begin
				if (_sv2v_0)
					;
				g_insn = SystemResourceCheck.axil_mem_ro.RDATA;
				if (g_stall || d_stall)
					g_insn = 32'h00000000;
			end
			wire [255:0] g_disasm;
			Disasm #(.PREFIX("G")) disasm_0get(
				.insn(g_insn),
				.disasm(g_disasm)
			);
			reg load_use_stall;
			reg div_stall;
			wire x_stall;
			reg [95:0] decode_state;
			always @(posedge clk)
				if (rst)
					decode_state <= 96'h000000000000000000000004;
				else if (branch_taken)
					decode_state <= 96'h000000000000000000000008;
				else if (d_stall)
					decode_state <= decode_state;
				else
					decode_state <= {sv2v_cast_32(get_state[63-:32]), g_insn, sv2v_cast_32(get_state[31-:32])};
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
			reg [170:0] memory_state;
			wire [6:0] m_insn_opcode = memory_state[113:107];
			wire m_stall = (m_insn_opcode == OpLoad) && !SystemResourceCheck.axil_mem_rw.RVALID;
			always @(posedge clk)
				if (rst)
					execute_state <= 175'h00000000000000000000000200000000000000000000;
				else if (x_stall || m_stall)
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
			wire insn_sb = (insn_opcode == OpStore) && (execute_state[125:123] == 3'b000);
			wire insn_sh = (insn_opcode == OpStore) && (execute_state[125:123] == 3'b001);
			wire insn_sw = (insn_opcode == OpStore) && (execute_state[125:123] == 3'b010);
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
			reg [31:0] addr_to_dmem;
			assign SystemResourceCheck.axil_mem_rw.BREADY = True;
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
				addr_to_dmem = 32'b00000000000000000000000000000000;
				SystemResourceCheck.axil_mem_rw.AWADDR = 32'b00000000000000000000000000000000;
				SystemResourceCheck.axil_mem_rw.AWVALID = False;
				SystemResourceCheck.axil_mem_rw.ARADDR = 32'b00000000000000000000000000000000;
				SystemResourceCheck.axil_mem_rw.ARVALID = False;
				SystemResourceCheck.axil_mem_rw.WSTRB = 4'b0000;
				SystemResourceCheck.axil_mem_rw.WDATA = 32'b00000000000000000000000000000000;
				SystemResourceCheck.axil_mem_rw.WVALID = False;
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
						if (insn_opcode == OpStore) begin
							SystemResourceCheck.axil_mem_rw.AWADDR = x_output_data;
							SystemResourceCheck.axil_mem_rw.AWVALID = True;
							SystemResourceCheck.axil_mem_rw.WVALID = True;
							if (insn_sb) begin
								case (x_output_data[1:0])
									2'b00: SystemResourceCheck.axil_mem_rw.WSTRB = 4'b0001;
									2'b01: SystemResourceCheck.axil_mem_rw.WSTRB = 4'b0010;
									2'b10: SystemResourceCheck.axil_mem_rw.WSTRB = 4'b0100;
									2'b11: SystemResourceCheck.axil_mem_rw.WSTRB = 4'b1000;
								endcase
								SystemResourceCheck.axil_mem_rw.WDATA = {4 {x_rs2_data[7:0]}};
							end
							else if (insn_sh) begin
								if (x_output_data[1])
									SystemResourceCheck.axil_mem_rw.WSTRB = 4'b1100;
								else
									SystemResourceCheck.axil_mem_rw.WSTRB = 4'b0011;
								SystemResourceCheck.axil_mem_rw.WDATA = {2 {x_rs2_data[15:0]}};
							end
							else if (insn_sw) begin
								SystemResourceCheck.axil_mem_rw.WSTRB = 4'b1111;
								SystemResourceCheck.axil_mem_rw.WDATA = x_rs2_data;
							end
						end
						else begin
							SystemResourceCheck.axil_mem_rw.ARADDR = x_output_data;
							SystemResourceCheck.axil_mem_rw.ARVALID = True;
						end
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
					if (dependent_d_rs1 || dependent_d_rs2)
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
			assign SystemResourceCheck.axil_mem_rw.RREADY = !m_stall;
			assign d_stall = ((load_use_stall || div_stall) || x_stall) || m_stall;
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
			always @(posedge clk)
				if (rst)
					memory_state <= 171'h0000000000000000000000010000000000000000000;
				else if (m_stall)
					memory_state <= memory_state;
				else
					memory_state <= m_next;
			wire [255:0] m_disasm;
			Disasm #(.PREFIX("M")) disasm_3memory(
				.insn(memory_state[138-:32]),
				.disasm(m_disasm)
			);
			wire insn_lb = (m_insn_opcode == OpLoad) && (memory_state[121:119] == 3'b000);
			wire insn_lh = (m_insn_opcode == OpLoad) && (memory_state[121:119] == 3'b001);
			wire insn_lw = (m_insn_opcode == OpLoad) && (memory_state[121:119] == 3'b010);
			wire insn_lbu = (m_insn_opcode == OpLoad) && (memory_state[121:119] == 3'b100);
			wire insn_lhu = (m_insn_opcode == OpLoad) && (memory_state[121:119] == 3'b101);
			reg [31:0] full_addr_to_dmem;
			reg [7:0] byte_val_dmem;
			reg [15:0] half_val_dmem;
			reg [31:0] m_load_data;
			reg [31:0] m_rs2_data;
			wire [31:0] m_rdata = SystemResourceCheck.axil_mem_rw.RDATA;
			always @(*) begin
				if (_sv2v_0)
					;
				m_load_data = 32'b00000000000000000000000000000000;
				m_rs2_data = memory_state[31-:32];
				full_addr_to_dmem = 32'b00000000000000000000000000000000;
				case (m_insn_opcode)
					OpLoad: begin
						full_addr_to_dmem = memory_state[63-:32];
						case (full_addr_to_dmem[1:0])
							2'b00: byte_val_dmem = m_rdata[7:0];
							2'b01: byte_val_dmem = m_rdata[15:8];
							2'b10: byte_val_dmem = m_rdata[23:16];
							2'b11: byte_val_dmem = m_rdata[31:24];
						endcase
						if (full_addr_to_dmem[1])
							half_val_dmem = m_rdata[31:16];
						else
							half_val_dmem = m_rdata[15:0];
						if (insn_lb)
							m_load_data = {{24 {byte_val_dmem[7]}}, byte_val_dmem};
						else if (insn_lh)
							m_load_data = {{16 {half_val_dmem[15]}}, half_val_dmem};
						else if (insn_lw)
							m_load_data = m_rdata;
						else if (insn_lbu)
							m_load_data = {24'b000000000000000000000000, byte_val_dmem};
						else if (insn_lhu)
							m_load_data = {16'b0000000000000000, half_val_dmem};
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
			wire can_mx_bypass = ((memory_state[73-:5] != 0) && (m_insn_opcode != OpStore)) && (m_insn_opcode != OpBranch);
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
			assign rd_data = w_rd_data;
			assign trace_completed_pc = writeback_state[165-:32];
			assign trace_completed_insn = writeback_state[133-:32];
			assign trace_completed_cycle_status = writeback_state[100-:32];
			initial _sv2v_0 = 0;
		end
	endgenerate
	assign datapath.clk = clk;
	assign datapath.rst = rst;
	assign led[0] = datapath.halt;
	assign trace_completed_pc = datapath.trace_completed_pc;
	assign trace_completed_insn = datapath.trace_completed_insn;
	assign trace_completed_cycle_status = datapath.trace_completed_cycle_status;
endmodule