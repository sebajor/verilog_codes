`default_nettype none
`include "includes.v"

module pfb_real_wideband #(
    parameter DIN_WIDTH = 8,
    parameter DIN_POINT = 7,
    parameter TAPS = 4,      //like im indexing using ascii 9 is the top number of taps
    parameter PFB_SIZE = 64, //for wola-fft should be the same as size of the FFT
    parameter LANES = 4,    //parallel inputs
    parameter COEFF_WIDTH = 18,
    parameter COEFF_POINT = 17,
    parameter COEFF_FILE = "",
    parameter DOUT_WIDTH = 18,
    parameter DOUT_POINT = 17,
    parameter PRE_MULT_LATENCY = 2,
    parameter MULT_LATENCY = 1,
    parameter DOUT_SHIFT = -1,
    parameter DOUT_DELAY = 0,
    parameter DEBUG = 0
)(
    input wire clk,
    input wire signed [LANES*DIN_WIDTH-1:0] din,
    input wire din_valid,
    input wire sync_in, 

    output wire signed [LANES*DOUT_WIDTH-1:0] dout,
    output wire dout_valid,
    output wire sync_out,
    output wire ovf_flag
);

wire [LANES-1:0] lane_ovf, lane_sync;

genvar i;
generate 
for( i=0; i<LANES; i=i+1)begin:pfb_loop
    localparam integer temp=48+i;   //
    localparam rom_text = {COEFF_FILE,"_",temp};

    wire signed [DIN_WIDTH-1:0] local_din = din[DIN_WIDTH*i+:DIN_WIDTH];
    wire signed [DOUT_WIDTH-1:0] local_dout;
    assign dout[DOUT_WIDTH*i+:DOUT_WIDTH] = local_dout;
    pfb_real_lane #(
        .DIN_WIDTH(DIN_WIDTH),
        .DIN_POINT(DIN_POINT),
        .TAPS(TAPS),
        .PFB_SIZE(PFB_SIZE),
        .COEFF_WIDTH(COEFF_WIDTH),
        .COEFF_POINT(COEFF_POINT),
        .COEFF_FILE(),
        .DOUT_WIDTH(DOUT_WIDTH),
        .DOUT_POINT(DOUT_POINT),
        .PRE_MULT_LATENCY(PRE_MULT_LATENCY),
        .MULT_LATENCY(MULT_LATENCY),
        .DOUT_SHIFT(DOUT_SHIFT),
        .DOUT_DELAY(DOUT_DELAY),
        .DEBUG(DEBUG)
    ) pfb_real_lane_inst (
        .clk(clk),
        .din(local_din),
        .din_valid(),
        .sync_in(), 
        .dout(local_dout),
        .dout_valid(),
        .sync_out(lane_sync[i]),
        .ovf_flag(lane_ovf[i])
    );
end
endgenerate

assign ovf_flag = |lane_ovf;
assign sync_out = lane_sync[0];


endmodule
