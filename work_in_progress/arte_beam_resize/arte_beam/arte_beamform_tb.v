`default_nettype none
`include "includes.v"
`include "arte_beamform.v"

module arte_beamform_tb #(
    parameter DIN_WIDTH = 18,
    parameter FFT_SIZE = 2048,
    parameter PARALLEL = 4,
    parameter COMPLEX_ADD_DELAY = 0,
    parameter POST_FLAG_DELAY = 0,
    parameter RFI_OUT_DELAY = 0,    
    parameter POWER_SHIFT = 10,
    parameter POWER_DELAY = 0,
    parameter POWER_WIDTH = 20,
    parameter POWER_POINT = 16,
    parameter DEBUG = 1
)(

    input wire clk,
    input wire sync_in,

    input wire signed [DIN_WIDTH-1:0] fft0_re0, fft0_re1, fft0_re2, fft0_re3,
    input wire signed [DIN_WIDTH-1:0] fft0_im0, fft0_im1, fft0_im2, fft0_im3,
    input wire signed [DIN_WIDTH-1:0] fft1_re0, fft1_re1, fft1_re2, fft1_re3,
    input wire signed [DIN_WIDTH-1:0] fft1_im0, fft1_im1, fft1_im2, fft1_im3,

    //fft flagging configuration
    input wire [31:0] config_flag,
    input wire [31:0] config_num,
    input wire config_en,
    //post flag output, these goes into the rfi subsystem
    output wire [DIN_WIDTH-1:0] flag_re0, flag_re1, flag_re2, flag_re3,
    output wire [DIN_WIDTH-1:0] flag_im0, flag_im1, flag_im2, flag_im3,
    output wire sig_sync,
    //for debugging    
    output wire cast_warning,
    output wire [POWER_WIDTH-1:0] pow0, pow1,pow2,pow3,
    output wire sync_pow_resize
);

arte_beamform#(
    .DIN_WIDTH(DIN_WIDTH),
    .FFT_SIZE(FFT_SIZE),
    .PARALLEL(PARALLEL),
    .COMPLEX_ADD_DELAY(COMPLEX_ADD_DELAY),
    .POST_FLAG_DELAY(POST_FLAG_DELAY),
    .RFI_OUT_DELAY(RFI_OUT_DELAY),
    .POWER_SHIFT(POWER_SHIFT),
    .POWER_DELAY(POWER_DELAY),
    .POWER_WIDTH(POWER_WIDTH),
    .POWER_POINT(POWER_POINT),
    .DEBUG(DEBUG)
) arte_beamform_inst(
    .clk(clk),
    .sync_in(sync_in),
    .fft0_re({fft0_re3, fft0_re2, fft0_re1, fft0_re0}),
    .fft0_im({fft0_im3, fft0_im2, fft0_im1, fft0_im0}),
    .fft1_re({fft1_re3, fft1_re2, fft1_re1, fft1_re0}),
    .fft1_im({fft1_im3, fft1_im2, fft1_im1, fft1_im0}),
    .config_flag(config_flag),
    .config_num(config_num),
    .config_en(config_en),
    .sig_flag_re({flag_re3, flag_re2, flag_re1, flag_re0}),
    .sig_flag_im({flag_im3, flag_im2, flag_im1, flag_im0}) ,
    .sig_sync(sig_sync),
    .cast_warning(cast_warning),
    .power_resize({pow3,pow2,pow1,pow0}),
    .sync_pow_resize(sync_pow_resize)
);

endmodule
