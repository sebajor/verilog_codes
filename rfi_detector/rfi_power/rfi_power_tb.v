`default_nettype none
`include "includes.v"
`include "rfi_power.v"

module rfi_power_tb #(
    parameter DIN_WIDTH = 9,
    parameter DIN_POINT = 8,
    parameter CHANNEL_ADDR = 11,
    parameter POST_POW_DELAY = 0,
    parameter ACC_WIDTH = 64,
    //convert the output of the accumulator
    parameter POST_ACC_SHIFT = 0,
    parameter POST_ACC_WIDTH = 32,
    parameter POST_ACC_POINT = 25,
    parameter POST_ACC_DELAY = 0,
    parameter DOUT_SHIFT = 0,
    parameter DOUT_WIDTH = 16,
    parameter DOUT_POINT = 8,
    parameter DEBUG = 1
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] sig_re, sig_im, ref_re, ref_im,
    input wire din_valid,
    input wire sync_in,

    input wire [31:0] acc_len,
    input wire cnt_rst,

    output wire [DOUT_WIDTH-1:0] dout,
    output wire dout_valid,

    output wire warning
);

rfi_power #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .CHANNEL_ADDR(CHANNEL_ADDR),
    .POST_POW_DELAY(POST_POW_DELAY),
    .ACC_WIDTH(ACC_WIDTH),
    .POST_ACC_SHIFT(POST_ACC_SHIFT),
    .POST_ACC_WIDTH(POST_ACC_WIDTH),
    .POST_ACC_POINT(POST_ACC_POINT),
    .POST_ACC_DELAY(POST_ACC_DELAY),
    .DOUT_SHIFT(DOUT_SHIFT),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT),
    .DEBUG(DEBUG)
) rfi_power_inst (
    .clk(clk),
    .sig_re(sig_re),
    .sig_im(sig_im),
    .ref_re(ref_re),
    .ref_im(ref_im),
    .din_valid(din_valid),
    .sync_in(sync_in),
    .acc_len(acc_len),
    .cnt_rst(cnt_rst),
    .dout(dout),
    .dout_valid(dout_valid),
    .warning(warning)
);

reg [31:0] counter=0;
always@(posedge clk)begin
    if(sync_in)
        counter <=0;
    else
        counter <= counter+1;

end

endmodule
