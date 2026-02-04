`timescale 1ns / 1ps

/**
 * @param a first 1-bit input
 * @param b second 1-bit input
 * @param g whether a and b generate a carry
 * @param p whether a and b would propagate an incoming carry
 */
module gp1(input wire a, b,
           output wire g, p);
   assign g = a & b;
   assign p = a | b;
endmodule

/**
 * Computes aggregate generate/propagate signals over a 4-bit window.
 * @param gin incoming generate signals
 * @param pin incoming propagate signals
 * @param cin the incoming carry
 * @param gout whether these 4 bits internally would generate a carry-out (independent of cin)
 * @param pout whether these 4 bits internally would propagate an incoming carry from cin
 * @param cout the carry outs for the low-order 3 bits
 */
module gp4(input wire [3:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [2:0] cout);
   assign pout = pin[0] & pin[1] & pin[2] & pin[3];
   assign gout = gin[0] & pin[1] & pin[2] & pin[3] |
                 gin[1] & pin[2] & pin[3] |
                 gin[2] & pin[3] |
                 gin[3];
   assign cout[0] = gin[0] | pin[0] & cin;
   assign cout[1] = gin[1] | pin[1] & gin[0] | 
                    pin[1] & pin[0] & cin;
   assign cout[2] = gin[2] | pin[2] & gin[1] | 
                    pin[2] & pin[1] & gin[0] | 
                    pin[2] & pin[1] & pin[0] & cin;
endmodule

/** Same as gp4 but for an 8-bit window instead */
module gp8(input wire [7:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [6:0] cout);
   wire gout_tmp1, pout_tmp1, gout_tmp2, pout_tmp2, c4;
   assign c4 = gout_tmp1 | (pout_tmp1 & cin);
   gp4 g1(.gin(gin[3:0]), .pin(pin[3:0]), .cin(cin), .gout(gout_tmp1), .pout(pout_tmp1), .cout(cout[2:0]));
   gp4 g2(.gin(gin[7:4]), .pin(pin[7:4]), .cin(c4), .gout(gout_tmp2), .pout(pout_tmp2), .cout(cout[6:3]));
   assign gout = gout_tmp2 | (pout_tmp2 & gout_tmp1);
   assign pout = pout_tmp1 & pout_tmp2;
endmodule

module CarryLookaheadAdder
  (input wire [31:0]  a, b,
   input wire         cin,
   output wire [31:0] sum);
   wire gout_tmp1, pout_tmp1, gout_tmp2, pout_tmp2, c4;
   assign c4 = gout_tmp1 | (pout_tmp1 & cin);
   gp8 g1(.gin(a[7:0]), .pin(pin[7:0]), .cin(cin), .gout(gout_tmp1), .pout(pout_tmp1), .cout(cout[6:0]));
   gp8 g2(.gin(a[15:8]), .pin(pin[15:8]), .cin(c4), .gout(gout_tmp2), .pout(pout_tmp2), .cout(cout[12:7]));
   gp8 g3(.gin(a[23:16]), .pin(pin[23:16]), .cin(cin), .gout(gout_tmp1), .pout(pout_tmp1), .cout(cout[18:0]));
   gp8 g4(.gin(a[31:24]), .pin(pin[31:24]), .cin(c4), .gout(gout_tmp2), .pout(pout_tmp2), .cout(cout[24:3]));
   assign gout = gout_tmp2 | (pout_tmp2 & gout_tmp1);
   assign pout = pout_tmp1 & pout_tmp2;
endmodule
