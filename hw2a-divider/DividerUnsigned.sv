/* INSERT NAME AND PENNKEY HERE */

`timescale 1ns / 1ns

// quotient = dividend / divisor

module DividerUnsigned (
    input  wire [31:0] i_dividend,
    input  wire [31:0] i_divisor,
    output wire [31:0] o_remainder,
    output wire [31:0] o_quotient
);
    wire [31:0] d[33], r[33], q[33];
    assign d[0] = i_dividend;
    assign r[0] = 32'b0;
    assign q[0] = 32'b0;
    genvar i;
    for (i = 0; i < 32; i = i + 1) begin
        DividerOneIter doi(.i_dividend(d[i]), .i_divisor(i_divisor), 
        .i_remainder(r[i]), .i_quotient(q[i]), 
        .o_dividend(d[i + 1]), .o_remainder(r[i + 1]), .o_quotient(q[i + 1]));
    end
    assign o_remainder = r[32];
    assign o_quotient = q[32];
endmodule


module DividerOneIter (
    input  wire [31:0] i_dividend,
    input  wire [31:0] i_divisor,
    input  wire [31:0] i_remainder,
    input  wire [31:0] i_quotient,
    output wire [31:0] o_dividend,
    output wire [31:0] o_remainder,
    output wire [31:0] o_quotient
);
  /*
    for (int i = 0; i < 32; i++) {
        remainder = (remainder << 1) | ((dividend >> 31) & 0x1);
        if (remainder < divisor) {
            quotient = (quotient << 1);
        } else {
            quotient = (quotient << 1) | 0x1;
            remainder = remainder - divisor;
        }
        dividend = dividend << 1;
    }
    */
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
