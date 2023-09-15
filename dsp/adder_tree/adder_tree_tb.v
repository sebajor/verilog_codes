//`include "adder_tree.v"
//`include "../delay/delay.v"

module adder_tree_tb #(
    parameter DATA_WIDTH = 8,
    parameter PARALLEL = 8,
    parameter DATA_TYPE = "signed"
) (
    input wire clk,
    input wire [DATA_WIDTH*PARALLEL-1:0] din,
    input wire din_valid,
    output wire [DATA_WIDTH+$clog2(PARALLEL)-1:0] dout,
    output wire dout_valid
);

adder_tree #(
    .DATA_WIDTH(DATA_WIDTH),
    .PARALLEL(PARALLEL),
    .DATA_TYPE(DATA_TYPE) 
) adder_tree_inst (
    .clk(clk),
    .din(din),
    .din_valid(din_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);

endmodule
