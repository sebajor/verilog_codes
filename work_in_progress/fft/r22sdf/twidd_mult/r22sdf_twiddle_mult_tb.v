`default_nettype none
`include "r22sdf_twiddle_mult.v"
`include "includes.v"

module r22sdf_twiddle_mult_tb #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    parameter FFT_SIZE = 64,
    parameter TWIDDLE_WIDTH = 16,
    parameter TWIDDLE_POINT = 14,
    parameter TWIDDLE_FILE = "twiddles/stage32_16_14",
    parameter DEBUG = 1
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din_re, din_im, 
    input wire din_valid,
    input wire rst,

    output wire signed [DIN_WIDTH-1:0] dout_re, dout_im,
    output wire dout_valid
);


r22sdf_twiddle_mult #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .FFT_SIZE(FFT_SIZE),
    .TWIDDLE_WIDTH(TWIDDLE_WIDTH),
    .TWIDDLE_POINT(TWIDDLE_POINT),
    .TWIDDLE_FILE(TWIDDLE_FILE),
    .DEBUG(DEBUG)
) r22sdf_twiddle_mult_inst (
    .clk(clk),
    .din_re(din_re),
    .din_im(din_im), 
    .din_valid(din_valid),
    .rst(rst),
    .dout_re(dout_re),
    .dout_im(dout_im),
    .dout_valid(dout_valid)
);

endmodule
