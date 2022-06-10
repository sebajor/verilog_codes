`default_nettype none
`include "includes.v"
`include "rfi_detection.v"

module rfi_detection_tb #(
    parameter DIN_WIDTH = 18,
    parameter CHANNEL_ADDR = 11,
    //first resize of the input data
    parameter CAST_SHIFT = 5,
    parameter CAST_DELAY = 0,
    parameter CAST_WIDHT = 9,
    parameter CAST_POINT = 8,
    //this parameter is for the correlation,
    //power we have a similar one but ww can calculate from here
    parameter POST_MULT_DELAY = 0,  
    //
    parameter ACC_WIDTH = 32,
    parameter POST_ACC_SHIFT = 0,
    parameter POST_ACC_WIDTH = 17,//32,
    parameter POST_ACC_POINT = 7,//16,
    parameter POST_ACC_DELAY = 0,
    //
    parameter DOUT_SHIFT =0,
    parameter DOUT_WIDTH = 18,
    parameter DOUT_POINT = 8,
    parameter DEBUG = 1
)(
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] sig_re, sig_im, ref_re, ref_im,
    input wire din_valid,
    input wire sync_in, 
    
    input wire [31:0] acc_len,
    input wire cnt_rst,
    
    output wire [DOUT_WIDTH-1:0] pow_data, corr_data,
    output wire dout_valid,
    output wire warning
);

rfi_detection #(
    .DIN_WIDTH(DIN_WIDTH),
    .CHANNEL_ADDR(CHANNEL_ADDR),
    .CAST_SHIFT(CAST_SHIFT),
    .CAST_DELAY(CAST_DELAY),
    .CAST_WIDHT(CAST_WIDHT),
    .CAST_POINT(CAST_POINT),
    .POST_MULT_DELAY(POST_MULT_DELAY),
    .ACC_WIDTH(ACC_WIDTH),
    .POST_ACC_SHIFT(POST_ACC_SHIFT),
    .POST_ACC_WIDTH(POST_ACC_WIDTH),
    .POST_ACC_POINT(POST_ACC_POINT),
    .POST_ACC_DELAY(POST_ACC_DELAY),
    .DOUT_SHIFT(DOUT_SHIFT),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT),
    .DEBUG(DEBUG)
) rfi_detection_inst (
    .clk(clk),
    .sig_re(sig_re),
    .sig_im(sig_im),
    .ref_re(ref_re),
    .ref_im(ref_im),
    .din_valid(din_valid),
    .sync_in(sync_in), 
    .acc_len(acc_len),
    .cnt_rst(cnt_rst),
    .pow_data(pow_data),
    .corr_data(corr_data),
    .dout_valid(dout_valid),
    .warning(warning)
);


endmodule
