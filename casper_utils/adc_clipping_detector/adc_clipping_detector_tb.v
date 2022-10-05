`default_nettype none
`include "adc_clipping_detector.v"


module adc_clipping_detector_tb #(
    parameter DIN_WIDTH = 8,
    parameter PARALLEL_STREAMS = 8
) (
    input wire clk, 
    input wire ce,

    input wire rst,
    input wire [DIN_WIDTH-1:0] din0, din1, din2,din3,din4,din5,din6,din7,

    output wire clip
);

adc_clipping_detector #(
    .DIN_WIDTH(DIN_WIDTH),
    .PARALLEL_STREAMS(PARALLEL_STREAMS)
) adc_clipping_detector_inst (
    .clk(clk), 
    .ce(ce),
    .rst(rst),
    .din({din7,din6,din5,din4,din3,din2,din1,din0}),
    .clip(clip)
);

endmodule
