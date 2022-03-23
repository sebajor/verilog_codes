`default_nettype none
`include "includes.v"
`include "point_doa_no_la.v"

module point_doa_no_la_tb #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    //correlator parameters
    parameter VECTOR_LEN = 64,
    parameter ACC_WIDTH = 20,
    parameter ACC_POINT = 16,
    parameter DOUT_WIDTH = 32
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din1_re, din1_im,
    input wire signed [DIN_WIDTH-1:0] din2_re, din2_im,
    input wire din_valid,

    input wire new_acc,     //new acc should come previos the first value of the frame
    output wire signed [DOUT_WIDTH-1:0] r11,r22,r12_re,r12_im,
    output wire dout_valid
);

point_doa_no_la #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .VECTOR_LEN(VECTOR_LEN),
    .ACC_WIDTH(ACC_WIDTH),
    .ACC_POINT(ACC_POINT),
    .DOUT_WIDTH(DOUT_WIDTH)
) point_doa_no_la_inst (
    .clk(clk),
    .din1_re(din1_re),
    .din1_im(din1_im),
    .din2_re(din2_re),
    .din2_im(din2_im),
    .din_valid(din_valid),
    .new_acc(new_acc),
    .r11(r11),
    .r22(r22),
    .r12_re(r12_re),
    .r12_im(r12_im),
    .dout_valid(dout_valid)
);

endmodule
