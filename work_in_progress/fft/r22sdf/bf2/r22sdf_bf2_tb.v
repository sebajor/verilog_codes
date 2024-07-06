`default_nettype none
`include "includes.v"
`include "../feedback_line.v"
`include "r22sdf_bf2.v"


module r22sdf_bf2_tb #(
    parameter DIN_WIDTH = 16,
    parameter FEEDBACK_SIZE = 8,
    parameter DELAY_TYPE = "delay",  //delay or bram
    parameter SCALE = 1,
    parameter ROUND_UP=1

) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din_re, din_im,
    input wire [1:0] control,
    output wire signed [DIN_WIDTH-1:0] dout_re, dout_im
);

r22sdf_bf2 #(
    .DIN_WIDTH(DIN_WIDTH),
    .FEEDBACK_SIZE(FEEDBACK_SIZE),
    .DELAY_TYPE(DELAY_TYPE),
    .SCALE(SCALE),
    .ROUND_UP(ROUND_UP)
) r22sdf_bf1_tb (
    .clk(clk),
    .din_re(din_re),
    .din_im(din_im),
    .control(control),
    .dout_re(dout_re),
    .dout_im(dout_im)
);

endmodule
