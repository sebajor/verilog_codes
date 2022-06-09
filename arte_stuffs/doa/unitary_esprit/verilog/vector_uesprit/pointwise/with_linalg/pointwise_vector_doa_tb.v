`default_nettype none
`include "includes.v"
`include "pointwise_vector_doa.v"


module pointwise_vector_doa_tb #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    //correlator parameters
    parameter VECTOR_LEN = 64,
    parameter ACC_WIDTH = 20,
    parameter ACC_POINT = 16,
    parameter ACC_DOUT_WIDTH = 32,
    //linear algebra parameters
    parameter ACC_SHIFT = -4,    //positive <<, negative >>
    parameter EIGEN_IN_WIDTH = 16,
    parameter EIGEN_IN_POINT = 10,
    parameter SQRT_IN_WIDTH = 12,
    parameter SQRT_IN_POINT = 6,
    parameter SQRT_OUT_WIDTH = 16,
    parameter SQRT_OUT_POINT = 10,
    parameter SQRT_MEM_FILE = "sqrt.mem",
    parameter DOUT_WIDTH = 16,
    parameter DOUT_POINT = 10
) (
    input wire clk,
    input wire new_acc, 
    
    input wire signed [DIN_WIDTH-1:0] din1_re, din1_im,
    input wire signed [DIN_WIDTH-1:0] din2_re, din2_im,
    input wire din_valid,

    output wire signed [DOUT_WIDTH-1:0] lamb1, lamb2,
    output wire signed [DOUT_WIDTH-1:0] eigen1_y, eigen2_y, eigen_x,
    //the correct eigen value is eigen_y/eigen_x, but the output of this
    //module goes into a arctan so we are happy with that :)
    output wire dout_valid,
    output wire dout_error
);

pointwise_vector_doa #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .VECTOR_LEN(VECTOR_LEN),
    .ACC_WIDTH(ACC_WIDTH),
    .ACC_POINT(ACC_POINT),
    .ACC_DOUT_WIDTH(ACC_DOUT_WIDTH),
    .ACC_SHIFT(ACC_SHIFT),
    .EIGEN_IN_WIDTH(EIGEN_IN_WIDTH),
    .EIGEN_IN_POINT(EIGEN_IN_POINT),
    .SQRT_IN_WIDTH(SQRT_IN_WIDTH),
    .SQRT_IN_POINT(SQRT_IN_POINT),
    .SQRT_OUT_WIDTH(SQRT_OUT_WIDTH),
    .SQRT_OUT_POINT(SQRT_OUT_POINT),
    .SQRT_MEM_FILE(SQRT_MEM_FILE),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT)
)pointwise_vector_doa_inst  (
    .clk(clk),
    .new_acc(new_acc), 
    .din1_re(din1_re), 
    .din1_im(din1_im),
    .din2_re(din2_re), 
    .din2_im(din2_im),
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
