`default_nettype none
`include "includes.v"
`include "sobel.v"

module sobel_tb #(
    parameter DIN_WIDTH = 8,
    parameter DIN_POINT = 0,
    parameter KERNEL_SIZE = 3,
    parameter WEIGHT_WIDTH = 8,
    parameter WEIGHT_POINT = 5,
    parameter X_SOBEL_FILE = "weight/x_sobel.mem",
    parameter Y_SOBEL_FILE = "weight/y_sobel.mem",
    parameter DOUT_WIDTH = 13,
    parameter DOUT_POINT = 1
) (
    input wire clk,
    input wire [DIN_WIDTH-1:0] din0,din1,din2,din3,din4,din5,din6,din7,din8,
    input wire din_valid,
    output wire [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);


sobel #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .KERNEL_SIZE(KERNEL_SIZE),
    .WEIGHT_WIDTH(WEIGHT_WIDTH),
    .WEIGHT_POINT(WEIGHT_POINT),
    .X_SOBEL_FILE(X_SOBEL_FILE),
    .Y_SOBEL_FILE(Y_SOBEL_FILE),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT)
) sobel_inst (
    .clk(clk),
    .din({din8,din7,din6,din5,din4,din3,din2,din1,din0}),
    .din_valid(din_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);

endmodule
