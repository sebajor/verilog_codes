`include "includes.v"
`include "r22sdf_bf1.v"
`include "../feedback_line.v"
`include "../fft_butterfly.v"

module r22sdf_bf1_tb #(
    parameter DIN_WIDTH = 16,
    parameter FEEDBACK_SIZE = 16,
    parameter DELAY_TYPE = "delay",//delay or bram
    parameter ROUND_UP = 1

) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din_re, din_im,
    input wire control,
    output wire signed [DIN_WIDTH:0] dout_re, dout_im
);

r22sdf_bf1 #(
    .DIN_WIDTH(DIN_WIDTH),
    .FEEDBACK_SIZE(FEEDBACK_SIZE),
    .DELAY_TYPE(DELAY_TYPE),
    .ROUND_UP(ROUND_UP)
) r22sdf_bf1_inst (
    .clk(clk),
    .din_re(din_re),
    .din_im(din_im),
    .control(control),
    .dout_re(dout_re),
    .dout_im(dout_im)
);

endmodule
