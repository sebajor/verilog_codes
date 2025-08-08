`default_nettype none
`include "includes.v"
`include "correlator_lane.v"

module correlator_lane_tb #(
    parameter DIN_WIDTH = 18,
    parameter DIN_POINT = 17,
    parameter VECTOR_LEN = 512,
    parameter MULT_DOUT = 2*DIN_WIDTH,
    parameter MULT_DELAY = 2,              //delay after the power computation
    parameter MULT_SHIFT = 0,
    parameter ACC_DIN_WIDTH = 2*DIN_WIDTH,
    parameter ACC_DIN_POINT = 2*DIN_POINT,
    parameter ACC_DOUT_WIDTH = 64,
    parameter DOUT_CAST_SHIFT = 0,
    parameter DOUT_CAST_DELAY = 0,
    parameter DOUT_WIDTH = 64,
    parameter DOUT_POINT = 2*DIN_POINT,
    parameter DEBUG = 1
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din0_re, din0_im, din1_re, din1_im,
    input wire din_valid,
    input wire sync_in,
    input wire [31:0] acc_len,
    input wire cnt_rst,

    output wire [DOUT_WIDTH-1:0] r11,r12_re, r12_im, r22,
    output wire dout_valid,
    output wire [$clog2(VECTOR_LEN)-1:0] dout_addr,
    output wire ovf_flag
);

correlator_lane #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .VECTOR_LEN(VECTOR_LEN),
    .MULT_DOUT(MULT_DOUT),
    .MULT_DELAY(MULT_DELAY),
    .MULT_SHIFT(MULT_SHIFT),
    .ACC_DIN_WIDTH(ACC_DIN_WIDTH),
    .ACC_DIN_POINT(ACC_DIN_POINT),
    .ACC_DOUT_WIDTH(ACC_DOUT_WIDTH),
    .DOUT_CAST_SHIFT(DOUT_CAST_SHIFT),
    .DOUT_CAST_DELAY(DOUT_CAST_DELAY),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT),
    .DEBUG(DEBUG)
) correlator_lane_inst (
    .clk(clk),
    .din0_re(din0_re),
    .din0_im(din0_im),
    .din1_re(din1_re),
    .din1_im(din1_im),
    .din_valid(din_valid),
    .sync_in(sync_in),
    .acc_len(acc_len),
    .cnt_rst(cnt_rst),
    .r11(r11),
    .r12_re(r12_re), 
    .r12_im(r12_im),
    .r22(r22),
    .dout_valid(dout_valid),
    .dout_addr(dout_addr),
    .ovf_flag(ovf_flag)
);

endmodule
