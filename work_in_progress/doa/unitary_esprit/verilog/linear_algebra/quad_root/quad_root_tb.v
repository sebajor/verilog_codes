`default_nettype none
`include "quad_root.v"
`include "includes.v"

module quad_root_tb #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    parameter SQRT_IN_WIDTH = 12,
    parameter SQRT_IN_POINT = 7,
    parameter DOUT_WIDTH = 16,
    parameter DOUT_POINT = 13,
    parameter SQRT_MEM_FILE = "sqrt.mem"
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] b,c,
    input wire din_valid,

    output wire signed [DOUT_WIDTH-1:0] x1,x2,
    output wire dout_valid,
    output wire dout_error
);

quad_root #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .SQRT_IN_WIDTH(SQRT_IN_WIDTH),
    .SQRT_IN_POINT(SQRT_IN_POINT),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT),
    .SQRT_MEM_FILE(SQRT_MEM_FILE)
)quad_root_inst (
    .clk(clk),
    .b(b),
    .c(c),
    .din_valid(din_valid),
    .x1(x1),
    .x2(x2),
    .dout_valid(dout_valid),
    .dout_error(dout_error)
);

endmodule
