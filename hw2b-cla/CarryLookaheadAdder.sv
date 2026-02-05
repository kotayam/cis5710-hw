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

module gpn(input wire [N-1:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [N-2:0] cout);
   parameter N = 1;
   // get pout
   assign pout = (& pin);

   // get gout
   genvar i;
   wire [N:0] tmp_out;
   for (i = 0; i < N-1; i = i + 1) begin
      assign tmp_out[i] = gin[i] & (& pin[N-1:i+1]);
   end
   assign tmp_out[N - 1] = gin[N - 1];
   assign gout = (| tmp_out);

   // get couts
   assign cout[0] = gin[0] | pin[0] & cin;
   genvar j;
   for (j = 1; j < N-1; j = j + 1) begin
      // get cout
      wire [j + 2:0] tmp_cout;
      assign tmp_cout[0] = gin[j];
      assign tmp_cout[1] = pin[j] & gin[j - 1];
      assign tmp_cout[j + 1] = (& pin[j:0]) & cin;
      genvar k;
      for (k = 0; k < j - 1; k = k + 1 ) begin
         assign tmp_cout[k + 2] = (& pin[j:k]) & gin[j - 2 - k];
      end
      assign cout[j] = (| tmp_cout);
   end
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
   gpn #(4) g4(.gin(gin), .pin(pin), .cin(cin), .gout(gout), .pout(pout), .cout(cout));
endmodule

/** Same as gp4 but for an 8-bit window instead */
module gp8(input wire [7:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [6:0] cout);
   gpn #(8) g8(.gin(gin), .pin(pin), .cin(cin), .gout(gout), .pout(pout), .cout(cout));
endmodule

module CarryLookaheadAdder
  (input wire [31:0]  a, b,
   input wire         cin,
   output wire [31:0] sum);

   // get 32-bit g and p
   genvar i;
   wire [31:0] g, p;
   for (i = 0; i < 32; i = i + 1) begin
      gp1 gp_inst(.a(a[i]), .b(b[i]), .g(g[i]), .p(p[i]));
   end

   // get 8 4-bit window g and p
   genvar j;
   wire[23:0] couts4;
   wire [7:0] g4, p4, cin4;
   assign cin4[0] = cin;
   for (j = 0; j < 8; j = j + 1) begin
      gp4 gp4_inst(.gin(g[j*4 +: 4]), .pin(p[j*4 +: 4]), .cin(cin4[j]), .gout(g4[j]), .pout(p4[j]), .cout(couts4[j*3 +: 3]));
   end

   // get 8-bit window 
   wire g8, p8;
   wire [6:0] cout8;
   gp8 gp8_inst(.gin(g4), .pin(p4), .cin(cin), .gout(g8), .pout(p8), .cout(cout8));

   // get full couts
   wire[31:0] couts;
   assign couts[0] = cin;
   // move couts from gp4s
   genvar k;
   for (k = 0; k < 8; k = k + 1) begin
      genvar l;
      for (l = 0; l < 3; l = l + 1) begin
         assign couts[k*4 + l + 1] = couts4[k*3 + l];
      end
   end
   // move couts from gp8
   genvar m;
   for (m = 0; m < 7; m = m + 1) begin
      assign couts[(m + 1) * 4] = cout8[m];
   end

   // get sum
   assign sum = a ^ b ^ couts;
endmodule
