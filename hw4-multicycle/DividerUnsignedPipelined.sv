/* INSERT NAME AND PENNKEY HERE */

`timescale 1ns / 1ns

// quotient = dividend / divisor

module DividerUnsignedPipelined (
    input wire clk, rst, stall,
    input  wire  [31:0] i_dividend,
    input  wire  [31:0] i_divisor,
    output logic [31:0] o_remainder,
    output logic [31:0] o_quotient
);
    // account for initial value and final result (8 + 2)
    logic [31:0] d_reg[9], r_reg[9], q_reg[9], div_reg[9];
    assign d_reg[0] = i_dividend;
    assign div_reg[0] = i_divisor;
    assign r_reg[0] = 32'b0;
    assign q_reg[0] = 32'b0;

    genvar i;
    for (i = 0; i < 8; i++) begin
        wire [31:0] d_tmp[5], r_tmp[5], q_tmp[5];
        assign d_tmp[0] = d_reg[i];
        assign r_tmp[0] = r_reg[i];
        assign q_tmp[0] = q_reg[i];
        genvar j;
        for (j = 0; j < 4; j++) begin
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

        always_ff @(posedge clk) begin
            if (rst) begin
                d_reg[i + 1] <= 32'b0;
                r_reg[i + 1] <= 32'b0;
                q_reg[i + 1] <= 32'b0;
                div_reg[i + 1] <= 32'b0;
            end else begin
                d_reg[i + 1] <= d_tmp[4];
                r_reg[i + 1] <= r_tmp[4];
                q_reg[i + 1] <= q_tmp[4];
                div_reg[i + 1] <= div_reg[i];
            end         
        end
    end
    assign o_remainder = r_reg[8];
    assign o_quotient = q_reg[8];
endmodule


module divu_1iter (
    input  wire  [31:0] i_dividend,
    input  wire  [31:0] i_divisor,
    input  wire  [31:0] i_remainder,
    input  wire  [31:0] i_quotient,
    output logic [31:0] o_dividend,
    output logic [31:0] o_remainder,
    output logic [31:0] o_quotient
);
    logic [31:0] r, q;
    always_comb begin
        r = (i_remainder << 1) | ((i_dividend >> 31) & 32'b1);
        q = i_quotient << 1;
        if (r >= i_divisor) begin
            q = q | 32'b1;
            r = r - i_divisor;
        end
    end
    assign o_dividend = i_dividend << 1;
    assign o_remainder = r;
    assign o_quotient = q;
endmodule
