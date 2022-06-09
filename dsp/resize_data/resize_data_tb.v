`default_nettype none
`include "includes.v"
`include "resize_data.v"

module resize_data_tb #(
    parameter DIN_WIDTH = 18,
    parameter DIN_POINT = 17,
    parameter DATA_TYPE = "signed",  //signed or unsigned
    parameter PARALLEL = 4,
    parameter SHIFT = 6,    //negative >>, positive <<
    parameter DELAY = 0,
    parameter DOUT_WIDTH = 9,
    parameter DOUT_POINT = 8,
    parameter DEBUG = 1
) (
    input wire clk, 
    input wire [DIN_WIDTH-1:0] din0_re, din0_im, din1_re, din1_im,
    input wire din_valid,
    input wire sync_in,

    output wire [DOUT_WIDTH-1:0] dout0_re, dout0_im, dout1_re,dout1_im,
    output wire dout_valid,
    output wire sync_out,
    output wire warning
);


resize_data #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .DATA_TYPE(DATA_TYPE),
    .PARALLEL(PARALLEL),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT),
    .DEBUG(DEBUG)
) resize_inst (
    .clk(clk), 
    .din({din0_re, din0_im,din1_re, din1_im}),
    .din_valid(din_valid),
    .sync_in(sync_in),
    .dout({dout0_re, dout0_im, dout1_re, dout1_im}),
    .dout_valid(dout_valid),
    .sync_out(sync_out),
    .warning(warning)
);

endmodule
