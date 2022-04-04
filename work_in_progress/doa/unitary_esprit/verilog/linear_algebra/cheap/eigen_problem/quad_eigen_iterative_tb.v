`default_nettype none
`include "includes.v"
`include "quad_eigen_iterative.v"


module quad_eigen_iterative_tb #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 15,
    parameter SQRT_WIDTH = 16,
    parameter SQRT_POINT = 8,
    parameter DOUT_WIDTH = 16,
    parameter DOUT_POINT = 13,
    parameter BANDS = 4,
    parameter FIFO_DEPTH = 8    //2**
) (
    input wire clk,

    input wire [DIN_WIDTH-1:0] r11, r22,
    input wire signed [DIN_WIDTH-1:0] r12,
    input wire din_valid,
    input wire [$clog2(BANDS)-1:0] band_in,

    output wire signed [DOUT_WIDTH-1:0] lamb1, lamb2,
    output wire signed [DOUT_WIDTH-1:0] eigen1_y, eigen2_y, eigen_x,
    //the correct eigen value is eigen_y/eigen_x, but the output of this
    //module goes into a arctan so we are happy with that :)
    output wire dout_valid,
    output wire dout_error,
    output wire [$clog2(BANDS)-1:0] band_out,
    output wire fifo_full
);

quad_eigen_iterative #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .SQRT_WIDTH(SQRT_WIDTH),
    .SQRT_POINT(SQRT_POINT),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT),
    .BANDS(BANDS),
    .FIFO_DEPTH(FIFO_DEPTH)
)quad_eigen_iterative_inst (
    .clk(clk),
    .r11(r11),
    .r22(r22),
    .r12(r12),
    .din_valid(din_valid),
    .band_in(band_in),
    .lamb1(lamb1),
    .lamb2(lamb2),
    .eigen1_y(eigen1_y),
    .eigen2_y(eigen2_y),
    .eigen_x(eigen_x),
    .dout_valid(dout_valid),
    .dout_error(dout_error),
    .band_out(band_out),
    .fifo_full(fifo_full)
);

endmodule
