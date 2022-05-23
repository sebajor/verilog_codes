`default_nettype none

/*
*   This is just to test the how the whole system works
*/

module arte_accumulator #(
    parameter DIN_WIDTH = 32,
    parameter DIN_POINT = 20,
    parameter FFT_CHANNEL =2048,
    parameter PARALLEL = 4,
    parameter INPUT_DELAY = 0,
    parameter OUTPUT_DELAY =0,
    parameter DOUT_WIDTH = 32,
    parameter DEBUG=1

)(
    input wire clk,
    input wire cnt_rst,

    input wire sync_in,
    input wire [DIN_WIDTH-1:0] pow0,pow1,pow2,pow3,

    input wire [31:0] acc_len,

    output wire [DOUT_WIDTH-1:0] dout,
    output wire dout_valid

);

wire [DIN_WIDTH+$clog2(PARALLEL)+1:0] dout_rebin;
wire rebin_valid;

arte_rebin #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .FFT_CHANNEL(FFT_CHANNEL),
    .PARALLEL(PARALLEL),
    .INPUT_DELAY(INPUT_DELAY),
    .OUTPUT_DELAY(OUTPUT_DELAY),
    .DEBUG(DEBUG)
) arte_rebin (
    .clk(clk),
    .cnt_rst(cnt_rst),
    .sync_in(sync_in),
    .power_resize({pow3,pow2,pow1,pow0}),
    .dout(dout_rebin),
    .dout_valid(rebin_valid)
);





