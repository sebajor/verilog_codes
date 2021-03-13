`default_nettype none 
`include "distortion.v"

module distortion_tb #(
    parameter DIN_WIDTH = 16,
    //parameter LOW_CLIP = -2**12,      //clipping values
    parameter HIGH_CLIP = 2**14,
    parameter CROSS_DISTORTION = 1, //1 or zero, if you want that effect
    parameter CROSS_THRESH = 2**12,  //(-thresh/2, thresh/2) 
    parameter CROSS_AMP = 1         //2**cross_amp

) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din,
    input wire din_tvalid,
    output wire din_tready,
    
    output wire signed [DIN_WIDTH-1:0] dout,
    output wire dout_tvalid,
    input wire dout_tready
);

distortion #(
    .DIN_WIDTH(DIN_WIDTH),
    //.LOW_CLIP(LOW_CLIP),
    .HIGH_CLIP(HIGH_CLIP),
    .CROSS_DISTORTION(CROSS_DISTORTION),
    .CROSS_THRESH(CROSS_THRESH),
    .CROSS_AMP(CROSS_AMP)

) distortion_tb (
    .clk(clk),
    .din(din),
    .din_tvalid(din_tvalid),
    .din_tready(din_tready),
    .dout(dout),
    .dout_tvalid(dout_tvalid),
    .dout_tready(dout_tready)
);

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end


endmodule
