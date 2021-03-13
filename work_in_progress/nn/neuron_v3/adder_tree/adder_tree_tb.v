`default_nettype none
`ifndef __head_adder_tree__
    `define __head_adder_tree__
    `include "adder_tree.v"
`endif

module adder_tree_tb #(
    parameter DATA_WIDTH = 8,
    parameter PARALLEL = 10
) (
    input wire clk,
    input wire [DATA_WIDTH*PARALLEL-1:0] din,
    input wire in_valid,
    output wire signed [31:0] dout, //keep this fix to decode in python
    output wire out_valid
);

wire [DATA_WIDTH+$clog2(PARALLEL)-1:0] dout_aux;

adder_tree #(
    .DATA_WIDTH(DATA_WIDTH),
    .PARALLEL(PARALLEL)
) adder_tree_inst (
    .clk(clk),
    .din(din),
    .in_valid(in_valid),
    .dout(dout_aux),
    .out_valid(out_valid)
);

assign dout = dout_aux;

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end

endmodule

