`default_nettype none
`include "includes.v"
`include "moving_average.v"

module moving_average_tb #(
    parameter DIN_WIDTH = 32,
    parameter DIN_POINT = 31,
    parameter WINDOW_LEN = 16,
    parameter DOUT_WIDTH = 32,
    parameter APPROX = "nearest"
) (
    input wire clk,
    input wire rst,
    input wire signed [DIN_WIDTH-1:0] din,
    input wire din_valid,
    output wire signed [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);



moving_average #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .WINDOW_LEN(WINDOW_LEN),
    .DOUT_WIDTH(DOUT_WIDTH),
    .APPROX(APPROX)
) moving_average_inst (
    .clk(clk),
    .rst(rst),
    .din(din),
    .din_valid(din_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);



endmodule 
