`default_nettype none
`ifndef __head_mult__
    `define __head_mult__
    `include "parallel_mult.v"
`endif


module parallel_mult_tb #(
    parameter PARALLEL = 4,
    parameter DIN1_WIDTH = 16,
    parameter DIN2_WIDTH = 16,
    parameter DOUT_WIDTH = 32
) (
    input wire clk,
    input wire [DIN1_WIDTH*PARALLEL-1:0] din1,
    input wire [DIN2_WIDTH*PARALLEL-1:0] din2,
    input wire din_valid,
    output wire [DOUT_WIDTH*PARALLEL-1:0] dout,
    output wire [PARALLEL-1:0] dout_valid
);

parallel_mult #(
    .PARALLEL(PARALLEL),
    .DIN1_WIDTH(DIN1_WIDTH), 
    .DIN2_WIDTH(DIN2_WIDTH),
    .DOUT_WIDTH(DOUT_WIDTH)
) parallel_mult_inst (
    .clk(clk),
    .din1(din1),
    .din2(din2),
    .din_valid(din_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end

endmodule
