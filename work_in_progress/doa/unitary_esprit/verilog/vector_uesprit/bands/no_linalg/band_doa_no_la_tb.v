`default_nettype none
`include "band_doa_no_la.v"
`include "includes.v"

module band_doa_no_la_tb #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    parameter PARALLEL = 4,     //parallel inputs
    parameter VECTOR_LEN = 64,      //FFT channels
    parameter BANDS = 4,            //
    //correlator  parameters
    parameter PRE_ACC_DELAY = 0,    //for timing
    parameter PRE_ACC_SHIFT = 0,    //positive <<, negative >>
    parameter ACC_WIDTH = 20,
    parameter ACC_POINT = 10,
    parameter DOUT_WIDTH = 32
) (
    input wire clk,
    input wire [DIN_WIDTH-1:0] din1_re0, din1_im0,
    input wire [DIN_WIDTH-1:0] din2_re0, din2_im0,
    input wire [DIN_WIDTH-1:0] din1_re1, din1_im1,
    input wire [DIN_WIDTH-1:0] din2_re1, din2_im1,
    input wire [DIN_WIDTH-1:0] din1_re2, din1_im2,
    input wire [DIN_WIDTH-1:0] din2_re2, din2_im2,
    input wire [DIN_WIDTH-1:0] din1_re3, din1_im3,
    input wire [DIN_WIDTH-1:0] din2_re3, din2_im3,

    input wire din_valid,
    input wire new_acc,     //this comes previous the first channel

    output wire signed [DOUT_WIDTH-1:0] r11,r22,r12,
    output wire dout_valid,
    output wire [$clog2(BANDS)-1:0] band_number
);

band_doa_no_la #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .PARALLEL(PARALLEL),
    .VECTOR_LEN(VECTOR_LEN),
    .BANDS(BANDS),
    .PRE_ACC_DELAY(PRE_ACC_DELAY),
    .PRE_ACC_SHIFT(PRE_ACC_SHIFT),
    .ACC_WIDTH(ACC_WIDTH),
    .ACC_POINT(ACC_POINT),
    .DOUT_WIDTH(DOUT_WIDTH)
) band_doa_no_la_inst (
    .clk(clk),
    .din1_re({din1_re3, din1_re2, din1_re1, din1_re0}),
    .din1_im({din1_im3, din1_im2, din1_im1, din1_im0}),
    .din2_re({din2_re3, din2_re2, din2_re1, din2_re0}),
    .din2_im({din2_im3, din2_im2, din2_im1, din2_im0}),
    .din_valid(din_valid),
    .new_acc(new_acc),
    .r11(r11),
    .r22(r22),
    .r12(r12),
    .dout_valid(dout_valid),
    .band_number(band_number)
);

endmodule
