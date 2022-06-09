`default_nettype none
`include "quad_root_iterative.v"
`include "includes.v"

module quad_root_iterative_tb #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    parameter SQRT_WIDTH = 12,
    parameter SQRT_POINT = 8,
    parameter FIFO_DEPTH = 8,    //Address= 2**FIFO_DEPTH
    parameter BANDS = 4
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] b,c,
    input wire din_valid,
    output wire fifo_full,
    input wire [$clog2(BANDS)-1:0] band_in,

    output wire signed [SQRT_WIDTH-1:0] x1,x2,
    output wire dout_valid,
    output wire dout_error,
    output wire [$clog2(BANDS)-1:0] band_out
);

quad_root_iterative #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .SQRT_WIDTH(SQRT_WIDTH),
    .SQRT_POINT(SQRT_POINT),
    .FIFO_DEPTH(FIFO_DEPTH),
    .BANDS(BANDS)
)quad_root_iter_inst  (
    .clk(clk),
    .b(b),
    .c(c),
    .din_valid(din_valid),
    .fifo_full(fifo_full),
    .band_in(band_in),
    .x1(x1),
    .x2(x2),
    .dout_valid(dout_valid),
    .dout_error(dout_error),
    .band_out(band_out)
);

endmodule
