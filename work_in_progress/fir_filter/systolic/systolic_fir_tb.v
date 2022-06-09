`default_nettype none
`include "includes.v"
`include "systolic_fir.v"

module systolic_fir_tb #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    parameter WEIGHT_WIDTH = 16,
    parameter WEIGHT_POINT = 14,
    parameter WEIGHT_SIZE = 8,
    parameter WEIGHT_FILE = "fir_weight.b",
    parameter DOUT_WIDTH = 32,  //this cast is after all the multpliyers
    parameter DOUT_POINT = 28
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din,
    input wire din_valid,

    output wire signed [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);

systolic_fir #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .WEIGHT_WIDTH(WEIGHT_WIDTH),
    .WEIGHT_POINT(WEIGHT_POINT),
    .WEIGHT_SIZE(WEIGHT_SIZE),
    .WEIGHT_FILE(WEIGHT_FILE),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT)
)systolic_fir_inst (
    .clk(clk),
    .din(din),
    .din_valid(din_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);

endmodule
