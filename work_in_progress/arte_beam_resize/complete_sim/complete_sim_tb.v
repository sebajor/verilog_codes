`default_nettype none
`include "includes.v"
`include "complete_sim.v"

module complete_sim_tb #(
    parameter DIN_WIDTH = 18,
    parameter FFT_SIZE = 2048,
    parameter PARALLEL = 4,
    parameter COMPLEX_ADD_DELAY = 0,
    parameter POST_FLAG_DELAY = 0,
    parameter RFI_OUT_DELAY = 0,    
    parameter POWER_SHIFT = 5,
    parameter POWER_DELAY = 0,
    parameter POWER_WIDTH = 18,//20,
    parameter POWER_POINT = 15,//17,
    parameter DOUT_WIDTH = 32,
    parameter ACC_IN_DELAY = 0,
    parameter ACC_OUT_DELAY =0,
    parameter DEBUG = 1
)(
    input wire clk,
    input wire sync_in,
    
    input wire signed [DIN_WIDTH-1:0] fft0_re0,fft0_re1,fft0_re2,fft0_re3,
    input wire signed [DIN_WIDTH-1:0] fft0_im0,fft0_im1,fft0_im2,fft0_im3,
    input wire signed [DIN_WIDTH-1:0] fft1_re0,fft1_re1,fft1_re2,fft1_re3,
    input wire signed [DIN_WIDTH-1:0] fft1_im0,fft1_im1,fft1_im2,fft1_im3,

    //fft flagging configuration
    input wire [31:0] config_flag,
    input wire [31:0] config_num,
    input wire config_en,
    //post flag output, these goes into the rfi subsystem
    output wire [DIN_WIDTH-1:0] sig_re0,sig_re1,sig_re2,sig_re3,
    output wire [DIN_WIDTH-1:0] sig_im0,sig_im1,sig_im2,sig_im3,
    output wire sig_sync,
    //for debugging    
    output wire cast_warning,
    //control
    input wire [31:0] acc_len,
    input wire cnt_rst,
    
    output wire [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);


complete_sim #(
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
    .DOUT_WIDTH(DOUT_WIDTH),
    .ACC_IN_DELAY(ACC_IN_DELAY),
    .ACC_OUT_DELAY(ACC_OUT_DELAY),
    .DEBUG(DEBUG)
) complete_sim_inst (
    .clk(clk),
    .sync_in(sync_in),
    .fft0_re({fft0_re3,fft0_re2,fft0_re1,fft0_re0}),
    .fft0_im({fft0_im3,fft0_im2,fft0_im1,fft0_im0}),
    .fft1_re({fft1_re3,fft1_re2,fft1_re1,fft1_re0}),
    .fft1_im({fft1_im3,fft1_im2,fft1_im1,fft1_im0}),
    .config_flag(config_flag),
    .config_num(config_num),
    .config_en(config_en),
    .sig_flag_re({sig_re3,sig_re2,sig_re1,sig_re0}), 
    .sig_flag_im({sig_im3,sig_im2,sig_im1,sig_im0}),
    .sig_sync(sig_sync),
    .cast_warning(cast_warning),
    .acc_len(acc_len),
    .cnt_rst(cnt_rst),
    .dout(dout),
    .dout_valid(dout_valid)
);

endmodule
