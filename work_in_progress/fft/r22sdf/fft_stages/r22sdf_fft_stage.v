`default_nettype none
`include "includes.v"

module r22sdft_fft_stage #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    parameter STAGE_NUMBER = 8,
    parameter TWIDDLE_WIDTH = 16,
    parameter TWIDDLE_POINT = 14,
    parameter DELAY_TYPE = "RAM",       //for stage_number=2 only the "DELAY" works!
    parameter DELAY_BUTTERFLIES = 0,
    parameter TWIDDLE_FILE = "twiddles"
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din_re, din_im,
    input wire din_valid,
    input wire rst,

    output wire signed [DIN_WIDTH+1:0] dout_re, dout_im,
    output wire dout_valid
);

wire signed [DIN_WIDTH:0] bf1_dout_re, bf1_dout_im;
wire bf1_dout_valid;

r22sdf_bf1 #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .BUFFER_SIZE(STAGE_NUMBER),
    .DELAY_TYPE(DELAY_TYPE)
) r22sdf_bf1_inst  (
    .clk(clk), 
    .din_re(din_re),
    .din_im(din_im),
    .din_valid(din_valid),
    .rst(rst),
    .dout_re(bf1_dout_re),
    .dout_im(bf1_dout_im),
    .dout_valid(bf1_dout_valid)
);

wire signed [DIN_WIDTH:0] bf1_dout_re_r, bf1_dout_im_r;
wire bf1_dout_valid_r;

delay #(
    .DATA_WIDTH(2*DIN_WIDTH+3),
    .DELAY_VALUE(DELAY_BUTTERFLIES)
) delay_inst (
    .clk(clk),
    .din({bf1_dout_re, bf1_dout_im, bf1_dout_valid}),
    .dout({bf1_dout_re_r, bf1_dout_im_r, bf1_dout_valid_r})
);

wire signed [DIN_WIDTH+1:0] bf2_dout_re, bf2_dout_im;
wire bf2_dout_valid;

r22sdf_bf2 #(
    .DIN_WIDTH(DIN_WIDTH+1),
    .DIN_POINT(DIN_POINT),
    .BUFFER_SIZE(STAGE_NUMBER/2),
    .DELAY_TYPE(DELAY_TYPE)
) r22sdf_bf2_inst (
    .clk(clk), 
    .din_re(bf1_dout_re_r),
    .din_im(bf1_dout_im_r),
    .din_valid(bf1_dout_valid_r),
    .rst(rst),
    .dout_re(bf2_dout_re),
    .dout_im(bf2_dout_im),
    .dout_valid(bf2_dout_valid)
);

wire signed [DIN_WIDTH+1:0] bf2_dout_re_r, bf2_dout_im_r;
wire bf2_dout_valid_r;


delay #(
    .DATA_WIDTH(2*DIN_WIDTH+5),
    .DELAY_VALUE(DELAY_BUTTERFLIES)
) delay_inst_2 (
    .clk(clk),
    .din({bf2_dout_re, bf2_dout_im, bf2_dout_valid}),
    .dout({bf2_dout_re_r, bf2_dout_im_r, bf2_dout_valid_r})
);

reg [$clog2(STAGE_NUMBER)+1:0] addr_counter = 0;

module rom #(
    .N_ADDR()
    .DATA_WIDTH(TWIDDLE_WIDTH)
    .INIT_VALS(TWIDDLE_FILE)
) rom_inst_re (
    .clk(clk),
    .ren(1'b1),
    .radd(),
    .wout()
);




endmodule
