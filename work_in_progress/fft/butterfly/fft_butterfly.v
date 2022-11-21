`default_nettype none

module fft_butterfly #(
    parameter DIN_WIDTH=16,
    parameter DIN_POINT=15,
    parameter TWIDDLE_WIDTH = 18,
    parameter TWIDDLE_POINT = 16
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din0_re, din0_im, din1_re, din_im,
    input wire signed [


)
