`default_nettype none
`include "includes.v"
`include "band_vector_doa.v"

module band_vector_doa_tb #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    parameter PARALLEL = 4,     //parallel inputs
    parameter VECTOR_LEN = 64,      //FFT channels
    parameter BANDS = 4,            //
    //correlator  parameters
    parameter PRE_ACC_DELAY = 0,    //for timing
    parameter PRE_ACC_SHIFT = 0,    //positive <<, negative >>
    parameter ACC_WIDTH = 26,
    parameter ACC_POINT = 16,
    parameter ACC_DOUT = 32,
    //linear algebra parameters
    parameter LA_DELAY_IN = 0,
    parameter LA_DIN_WIDTH = 32,
    parameter LA_DIN_POINT = 16,
    parameter SQRT_WIDTH = 32,
    parameter SQRT_POINT = 16,
    parameter DOUT_WIDTH = 32,
    parameter DOUT_POINT = 16,
    parameter FIFO_DEPTH = 8
) (
    
    input wire clk,
    
    input wire signed [DIN_WIDTH-1:0] din1_re0, din1_im0,
    input wire signed [DIN_WIDTH-1:0] din1_re1, din1_im1,
    input wire signed [DIN_WIDTH-1:0] din1_re2, din1_im2,
    input wire signed [DIN_WIDTH-1:0] din1_re3, din1_im3,
    
    
    input wire signed [DIN_WIDTH-1:0] din2_re0, din2_im0,
    input wire signed [DIN_WIDTH-1:0] din2_re1, din2_im1,
    input wire signed [DIN_WIDTH-1:0] din2_re2, din2_im2,
    input wire signed [DIN_WIDTH-1:0] din2_re3, din2_im3,
    

    input wire din_valid,
    input wire new_acc,     //this comes previous the first channel

    output wire signed [DOUT_WIDTH-1:0] lamb1, lamb2,
    output wire signed [DOUT_WIDTH-1:0] eigen1_y, eigen2_y, eigen_x,
    //the correct eigen value is eigen_y/eigen_x, but the output of this
    //module goes into a arctan so we are happy with that :)
    output wire dout_valid,
    output wire dout_error,
    output wire [$clog2(BANDS)-1:0] band_out,
    output wire fifo_full

);

band_vector_doa #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .PARALLEL(PARALLEL),
    .VECTOR_LEN(VECTOR_LEN),
    .BANDS(BANDS),
    .PRE_ACC_DELAY(PRE_ACC_DELAY),
    .PRE_ACC_SHIFT(PRE_ACC_SHIFT),
    .ACC_WIDTH(ACC_WIDTH),
    .ACC_POINT(ACC_POINT),
    .ACC_DOUT(ACC_DOUT),
    .LA_DELAY_IN(LA_DELAY_IN),
    .LA_DIN_WIDTH(LA_DIN_WIDTH),
    .LA_DIN_POINT(LA_DIN_POINT),
    .SQRT_WIDTH(SQRT_WIDTH),
    .SQRT_POINT(SQRT_POINT),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT),
    .FIFO_DEPTH(FIFO_DEPTH)
) band_vector_doa_inst (
    .clk(clk),
    .din1_re({din1_re3, din1_re2, din1_re1, din1_re0}),
    .din1_im({din1_im3, din1_im2, din1_im1, din1_im0}),
    .din2_re({din2_re3, din2_re2, din2_re1, din2_re0}),
    .din2_im({din2_im3, din2_im2, din2_im1, din2_im0}),
    .din_valid(din_valid),
    .new_acc(new_acc),
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

reg [31:0] count=0;
always@(posedge clk)begin
    if(new_acc)
        count <=0;
    else
        count <= count+1;

end


endmodule
