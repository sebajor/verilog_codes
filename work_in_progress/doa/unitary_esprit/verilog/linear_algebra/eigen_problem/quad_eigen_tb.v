`default_nettype none
`include "includes.v"
`include "quad_eigen.v"


module quad_eigen_tb #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 15,
    parameter SQRT_IN_WIDTH = 12,
    parameter SQRT_IN_POINT = 7,
    parameter SQRT_OUT_WIDTH = 16,
    parameter SQRT_OUT_POINT = 13,
    parameter SQRT_MEM_FILE = "sqrt.mem",
    parameter DOUT_WIDTH = 19,
    parameter DOUT_POINT = 12
) (
    input wire clk,
    input wire [DIN_WIDTH-1:0] r11, r22,
    input wire signed [DIN_WIDTH-1:0] r12,
    input wire din_valid,
    output wire signed [DOUT_WIDTH-1:0] lamb1, lamb2,
    output wire signed [DOUT_WIDTH-1:0] eigen1_y, eigen2_y, eigen_x,
    output wire dout_valid,
    output wire dout_error
);


quad_eigen #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .SQRT_IN_WIDTH(SQRT_IN_WIDTH),
    .SQRT_IN_POINT(SQRT_IN_POINT),
    .SQRT_OUT_WIDTH(SQRT_OUT_WIDTH),
    .SQRT_OUT_POINT(SQRT_OUT_POINT),
    .SQRT_MEM_FILE(SQRT_MEM_FILE),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT)
)quad_eigen_inst (
    .clk(clk),
    .r11(r11),
    .r22(r22),
    .r12(r12),
    .din_valid(din_valid),
    .lamb1(lamb1),
    .lamb2(lamb2),
    .eigen1_y(eigen1_y),
    .eigen2_y(eigen2_y),
    .eigen_x(eigen_x),
    .dout_valid(dout_valid),
    .dout_error(dout_error)
);

endmodule
