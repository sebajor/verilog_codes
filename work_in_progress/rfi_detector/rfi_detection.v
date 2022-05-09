`default_nettype none

module rfi_detection #(
    parameter DIN_WIDTH = 18,
    parameter CHANNEL_ADDR = 11,
    //first resize of the input data
    parameter CAST_SHIFT = 6,
    parameter CAST_DELAY = 0,
    parameter CAST_WIDHT = 9,
    parameter CAST_POINT = 8,
    //this parameter is for the correlation,
    //power we have a similar one but ww can calculate from here
    parameter POST_MULT_DELAY = 0,  
    //
    parameter ACC_WIDTH = 32,
    parameter POST_ACC_SHIFT = 0,
    parameter POST_ACC_WIDTH = 32,
    parameter POST_ACC_POINT = 16,
    parameter POST_ACC_DELAY = 0,
    //
    parameter DOUT_SHIFT =0,
    parameter DOUT_WIDTH = 16,
    parameter DOUT_POINT = 12,
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

wire signed [CAST_WIDHT-1:0] dat0_re, dat0_im, dat1_re, dat1_im;
wire in_warn, valid_cast, sync_cast;

resize_module #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_WIDTH-1),
    .DATA_TYPE("signed"),
    .PARALLEL(4),
    .SHIFT(CAST_SHIFT),
    .DELAY(CAST_DELAY),
    .DOUT_WIDTH(CAST_WIDHT),
    .DOUT_POINT(CAST_POINT),
    .DEBUG(DEBUG)
)input_resize (
    .clk(clk), 
    .din({sig_re, sig_im, ref_re, ref_im}),
    .din_valid(din_valid),
    .sync_in(sync_in),
    .dout({dat0_re,dat0_im,dat1_re,dat1_im}),
    .dout_valid(valid_cast),
    .sync_out(sync_cast),
    .warning(in_warn)
);

wire corr_warn;

rfi_correlation #(
    .DIN_WIDTH(CAST_WIDHT),
    .DIN_POINT(CAST_POINT),
    .CHANNEL_ADDR(CHANNEL_ADDR),
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
) rfi_correlation_inst (
    .clk(clk),
    .sig_re(dat0_re),
    .sig_im(dat0_im),
    .ref_re(dat1_re),
    .ref_im(dat1_im),
    .din_valid(valid_cast),
    .sync_in(sync_cast),
    .acc_len(acc_len),
    .cnt_rst(cnt_rst),
    .dout(corr_data),
    .dout_valid(dout_valid),
    .warning(corr_warn)
);

wire power_warn;

rfi_power #(
    .DIN_WIDTH(CAST_WIDHT),
    .DIN_POINT(CAST_POINT),
    .CHANNEL_ADDR(CHANNEL_ADDR),
    .POST_POW_DELAY(POST_MULT_DELAY),
    .ACC_WIDTH(ACC_WIDTH),
    .POST_ACC_SHIFT(POST_ACC_SHIFT),
    .POST_ACC_WIDTH(POST_ACC_WIDTH),
    .POST_ACC_POINT(POST_ACC_POINT),
    .POST_ACC_DELAY(POST_ACC_DELAY+2),
    .DOUT_SHIFT(DOUT_SHIFT),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT),
    .DEBUG(DEBUG)
) rfi_power_inst (
    .clk(clk),
    .sig_re(dat0_re),
    .sig_im(dat0_im),
    .ref_re(dat1_re),
    .ref_im(dat1_im),
    .din_valid(valid_cast),
    .sync_in(sync_cast),
    .acc_len(acc_len),
    .cnt_rst(cnt_rst),
    .dout(pow_data),
    .dout_valid(),
    .warning(power_warn)
);

generate
if(DEBUG)
    assign warning = (in_warn |power_warn| corr_warn);
else
    assign warning =0;
endgenerate

endmodule
