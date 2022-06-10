`default_nettype none
`include "includes.v"
`include "arte_rebin.v"

module arte_rebin_tb #(
    parameter DIN_WIDTH = 20,
    parameter DIN_POINT = 16,
    parameter FFT_CHANNEL =2048,
    parameter PARALLEL = 4,
    parameter INPUT_DELAY = 0,
    parameter OUTPUT_DELAY =0,
    parameter DEBUG=1
)(
    input wire clk,
    input wire cnt_rst,
    input wire sync_in,
    input wire [DIN_WIDTH-1:0] pow0,pow1,pow2,pow3,
    output wire [DIN_WIDTH+$clog2(PARALLEL)+1:0] dout,
    output wire dout_valid 
);


arte_rebin #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .FFT_CHANNEL(FFT_CHANNEL),
    .PARALLEL(PARALLEL),
    .INPUT_DELAY(INPUT_DELAY),
    .OUTPUT_DELAY(OUTPUT_DELAY),
    .DEBUG(DEBUG)
)arte_rebin_inst (
    .clk(clk),
    .sync_in(sync_in),
    .cnt_rst(cnt_rst),
    .power_resize({pow3,pow2,pow1,pow0}),
    .dout(dout),
    .dout_valid(dout_valid)
);

reg [31:0] counter=0;
always@(posedge clk)begin
    if(sync_in)
        counter <=0;
    else
        counter <= counter+1;
end

endmodule
