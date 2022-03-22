`default_nettype none

/*
*   Author: Sebastian Jorquera
*   This module allows to flag certain channels of the FFT to zero.
*   The FFTs could enter in several streams to this module.
*   
*   The channels are encoded in packets, in one clock cycle the module
*   receive STREAMS channels that are encoded in the bits of the config_flag.
*   To select a given channel you have to set the config_num to a certain value
*   and then put a 1 in the correspondant channel that you want to flag.
*
*   Example:  a 1024 channel FFT with 8 streams will give us 128 channels,
*   if for example we want to flag the channel 765 first we set the config_num
*   to 765//8 = 95, and the position of that channel will be 765%8=5 inside the
*   packet so we set config_flag to 32'b100000 
*
*/

module fft_chann_flag #(
    parameter STREAMS = 8,
    parameter FFT_SIZE = 1024,
    parameter DIN_WIDTH = 36
) (
    input wire clk,
    input wire sync_in,
    input wire [STREAMS*DIN_WIDTH-1:0] din,
    output wire sync_out,
    output wire [STREAMS*DIN_WIDTH-1:0] dout,

    //config
    input wire [31:0] config_flag,
    input wire [31:0] config_num,
    input wire config_en
);

localparam FFT_CYCLES = FFT_SIZE/STREAMS;
//localparam FLAGS = FFT_SIZE/32;

reg [STREAMS-1:0] flags [FFT_CYCLES-1:0];

integer j;
initial begin
    for(j=0; j<FFT_CYCLES; j=j+1)
        flags[j] <= 32'h0;
end

always@(posedge clk)begin
    if(config_en)
        flags[config_num] <= config_flag[STREAMS-1:0];
end

reg [$clog2(FFT_CYCLES)-1:0] cycles_count=0;

always@(posedge clk)begin
    if(sync_in)
        cycles_count <=0;
    else begin
        cycles_count <= cycles_count+1;
    end
end 

reg [STREAMS*DIN_WIDTH-1:0] dout_r=0;
assign dout = dout_r;
integer i;
always@(posedge clk)begin
    for(i=0; i<STREAMS; i=i+1)begin
        if(flags[cycles_count][i])
            dout_r[DIN_WIDTH*i+:DIN_WIDTH] <= 0;
        else
            dout_r[DIN_WIDTH*i+:DIN_WIDTH] <= din[DIN_WIDTH*i+:DIN_WIDTH];
    end
end

wire [STREAMS-1:0] debug = flags[cycles_count];

reg sync_out_r=0;
assign sync_out = sync_out_r;

always@(posedge clk)
    sync_out_r <= sync_in;


endmodule
