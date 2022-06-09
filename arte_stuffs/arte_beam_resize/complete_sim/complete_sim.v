`default_nettype none

module complete_sim #(
    parameter DIN_WIDTH = 18,
    parameter FFT_SIZE = 2048,
    parameter PARALLEL = 4,
    parameter COMPLEX_ADD_DELAY = 0,
    parameter POST_FLAG_DELAY = 0,
    parameter RFI_OUT_DELAY = 0,    
    parameter POWER_SHIFT = 0,
    parameter POWER_DELAY = 0,
    parameter POWER_WIDTH = 18,
    parameter POWER_POINT = 17,
    parameter DOUT_WIDTH = 32,
    parameter ACC_IN_DELAY = 0,
    parameter ACC_OUT_DELAY =0,
    parameter DEBUG = 1
)(

    input wire clk,
    input wire sync_in,
    input wire [PARALLEL*DIN_WIDTH-1:0] fft0_re, fft0_im, fft1_re, fft1_im,
    //fft flagging configuration
    input wire [31:0] config_flag,
    input wire [31:0] config_num,
    input wire config_en,
    //post flag output, these goes into the rfi subsystem
    output wire [PARALLEL*DIN_WIDTH-1:0] sig_flag_re, sig_flag_im,
    output wire sig_sync,
    //for debugging    
    output wire cast_warning,
    //control
    input wire [31:0] acc_len,
    input wire cnt_rst,
    
    output wire [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);

localparam DIN_POINT = DIN_WIDTH-1;

wire [POWER_WIDTH*PARALLEL-1:0] power_resize;
wire sync_pow_resize;

arte_beamform #(
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
) arte_beamform_inst (
    .clk(clk),
    .sync_in(sync_in),
    .fft0_re(fft0_re),
    .fft0_im(fft0_im),
    .fft1_re(fft1_re),
    .fft1_im(fft1_im),
    .config_flag(config_flag),
    .config_num(config_num),
    .config_en(config_en),
    .sig_flag_re(sig_flag_re),
    .sig_flag_im(sig_flag_im),
    .sig_sync(sig_sync),
    .cast_warning(cast_warning),
    .power_resize(power_resize),
    .sync_pow_resize(sync_pow_resize)
);


arte_accumulator #(
    .DIN_WIDTH(POWER_WIDTH),
    .DIN_POINT(POWER_POINT),
    .FFT_CHANNEL(FFT_SIZE),
    .PARALLEL(PARALLEL),
    .INPUT_DELAY(ACC_IN_DELAY),
    .OUTPUT_DELAY(ACC_OUT_DELAY),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DEBUG(DEBUG)
) arte_accumulator (
    .clk(clk),
    .cnt_rst(cnt_rst),
    .sync_in(sync_pow_resize),
    .power(power_resize),
    .acc_len(acc_len),
    .dout(dout),
    .dout_valid(dout_valid)
);

endmodule
