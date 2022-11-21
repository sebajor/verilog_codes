`default_nettype none


/*
*   Author: Sebastian Jorquera
*   Simple clipping detector. The inputs are signed numbers, so the max positive 
*   value is 01111...1 and the most negative number is 1000...00
*   If one of those is found then the clip output goes to 1 until it gets reset.
*/


module adc_clipping_detector #(
    parameter DIN_WIDTH = 8,
    parameter PARALLEL_STREAMS = 8
) (
    input wire clk, 
    input wire ce,

    input wire rst,
    input wire [PARALLEL_STREAMS*DIN_WIDTH-1:0] din,

    output wire clip
);

wire [PARALLEL_STREAMS-1:0] ovf_flag;

single_ovf #(
    .DIN_WIDTH(DIN_WIDTH)
) single_ovf_inst [PARALLEL_STREAMS-1:0] (
    .clk(clk),
    .rst(rst),
    .din(din),
    .clip(ovf_flag)
);


assign clip = |ovf_flag;


endmodule

module single_ovf#(
    parameter DIN_WIDTH = 8
) (
    input wire clk,
    input wire rst,
    input wire [DIN_WIDTH-1:0] din,
    
    output wire clip
);

reg ovf=0;
always@(posedge clk)begin
    if(rst)
        ovf <=0;
    else if(din[DIN_WIDTH-1] & (&(~din[DIN_WIDTH-2:0])))
        ovf <= 1;
    else if(~din[DIN_WIDTH-1] & (&din[DIN_WIDTH-2:0]))
        ovf <= 1;
end

assign clip = ovf;


endmodule





