`default_nettype none
`include "fir_tap_dsp48.v"

module fir_tap_dsp48_tb #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    parameter COEF_WIDTH = 16,
    parameter COEF_POINT = 14,
    parameter POST_ADD = 48
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] pre_add1, pre_add2,
    input wire signed [COEF_WIDTH-1:0] coeff,
    input wire signed [POST_ADD-1:0] post_add,
    input wire din_valid,
    
    output wire signed [POST_ADD-1:0] dout,
    output wire dout_valid
);


fir_tap_dsp48 #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .COEF_WIDTH(COEF_WIDTH),
    .COEF_POINT(COEF_POINT),
    .POST_ADD(POST_ADD)
) fir_tap_dsp48_tb (
    .clk(clk),
    .pre_add1(pre_add1),
    .pre_add2(pre_add2),
    .coeff(coeff),
    .post_add(post_add),
    .din_valid(din_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);


endmodule
