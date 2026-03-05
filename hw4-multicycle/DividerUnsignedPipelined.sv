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
    wire [31:0] d_tmp[5], r_tmp[5], q_tmp[5];
    logic [31:0] d_res, r_res, q_res;
    logic [3:0] count = 0;

    // set first div input
    assign d_tmp[0] = (count == 0) ? i_dividend : d_res;
    assign r_tmp[0] = (count == 0) ? 32'b0 : r_res;
    assign q_tmp[0] = (count == 0) ? 32'b0 : q_res;

    genvar i;
    for (i = 0; i < 4; i++) begin
        divu_1iter doi(
            .i_dividend(d_tmp[i]), 
            .i_divisor(i_divisor), 
            .i_remainder(r_tmp[i]), 
            .i_quotient(q_tmp[i]),
            .o_dividend(d_tmp[i + 1]), 
            .o_remainder(r_tmp[i + 1]),
            .o_quotient(q_tmp[i + 1])
        );
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            count <= 0;
        end else begin
            // use most recent calculation result
            d_res <= d_tmp[4];
            r_res <= r_tmp[4];
            q_res <= q_tmp[4];
            if (count < 7) begin
                count <= count + 1;
            end else begin 
                // Done
                count <= 0;
            end
        end
    end

    assign o_remainder = r_res;
    assign o_quotient = q_res;
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
