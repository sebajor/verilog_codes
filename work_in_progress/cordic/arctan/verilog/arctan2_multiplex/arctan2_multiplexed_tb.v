`default_nettype none
`include "includes.v"
`include "arctan2_multiplexed.v"

module arctan2_multiplexed_tb #(
    parameter DIN_WIDTH = 16,
    parameter DOUT_WIDTH = 16,
    parameter PARALLEL = 4,
    parameter ROM_FILE = "atan_rom.mem",
    parameter MAX_SHIFT = 7,
    parameter FIFO_DEPTH = 8    //2**
) (
    input wire clk,
    input wire rst,
    input wire [DIN_WIDTH-1:0] x0,y0,
    input wire [DIN_WIDTH-1:0] x1,y1,
    input wire [DIN_WIDTH-1:0] x2,y2,
    input wire [DIN_WIDTH-1:0] x3,y3,

    input wire din_valid,

    output wire [DOUT_WIDTH-1:0] dout, 
    output wire dout_valid,
    output wire fifo_full
);


arctan2_multiplexed #(
    .DIN_WIDTH(DIN_WIDTH),
    .DOUT_WIDTH(DOUT_WIDTH),
    .PARALLEL(PARALLEL),
    .ROM_FILE(ROM_FILE),
    .MAX_SHIFT(MAX_SHIFT),
    .FIFO_DEPTH(FIFO_DEPTH)
) arctan2_multiplex_inst (
    .clk(clk),
    .rst(rst),
    .x({x3,x2,x1,x0}),
    .y({y3,y2,y1,y0}),
    .din_valid(din_valid),
    .dout(dout), 
    .dout_valid(dout_valid),
    .fifo_full(fifo_full)
);

endmodule
