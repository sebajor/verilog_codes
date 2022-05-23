`default_nettype none
`include "includes.v"
`include "../arte_rebin/arte_rebin.v"
`include "arte_accumulator.v"

module arte_accumulator_tb #(
    parameter DIN_WIDTH = 20,
    parameter DIN_POINT = 16,
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

arte_accumulator #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .FFT_CHANNEL(FFT_CHANNEL),
    .PARALLEL(PARALLEL),
    .INPUT_DELAY(INPUT_DELAY),
    .OUTPUT_DELAY(OUTPUT_DELAY),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DEBUG(DEBUG)
) arte_accumulator_inst (
    .clk(clk),
    .cnt_rst(cnt_rst),
    .sync_in(sync_in),
    .power({pow3,pow2,pow1,pow0}),
    .acc_len(acc_len),
    .dout(dout),
    .dout_valid(dout_valid)
);

endmodule
