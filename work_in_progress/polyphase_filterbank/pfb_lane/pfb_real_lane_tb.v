`default_nettype none
`include "includes.v"
`include "pfb_real_lane.v"

module pfb_real_lane_tb #(
    parameter DIN_WIDTH = 8,
    parameter DIN_POINT = 7,
    parameter TAPS = 8,
    parameter PFB_SIZE = 1024/8, ///this should be FFT_SIZE/LANES
    parameter COEFF_WIDTH = 18,
    parameter COEFF_POINT = 17,
    parameter COEFF_FILE = "pfb_coeff/pfb_coeff_0",
    parameter DOUT_WIDTH = 18,
    parameter DOUT_POINT = 17,
    parameter PRE_MULT_LATENCY = 1,
    parameter MULT_LATENCY = 1,
    parameter DOUT_SHIFT = -1,
    parameter DOUT_DELAY = 0,
    parameter DEBUG = 1
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din,
    input wire din_valid,
    input wire sync_in, 

    output wire signed [DOUT_WIDTH-1:0] dout,
    output wire dout_valid,
    output wire sync_out,
    output wire ovf_flag
);


pfb_real_lane #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .TAPS(TAPS),
    .PFB_SIZE(PFB_SIZE),
    .COEFF_WIDTH(COEFF_WIDTH),
    .COEFF_POINT(COEFF_POINT),
    .COEFF_FILE(COEFF_FILE),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT),
    .PRE_MULT_LATENCY(PRE_MULT_LATENCY),
    .MULT_LATENCY(MULT_LATENCY),
    .DOUT_SHIFT(DOUT_SHIFT),
    .DOUT_DELAY(DOUT_DELAY),
    .DEBUG(DEBUG)
) pfb_real_lane_inst (
    .clk(clk),
    .din(din),
    .din_valid(din_valid),
    .sync_in(sync_in), 
    .dout(dout),
    .dout_valid(dout_valid),
    .sync_out(sync_out),
    .ovf_flag(ovf_flag)
);

reg [31:0] debug=0;
reg flag =0;
always@(posedge clk)begin
    if(sync_in)
        flag <= 1;
    else  if(sync_out)
        flag <=0;
end
always@(posedge clk)begin
    if(flag)
        debug<= debug+1;
end 

endmodule
