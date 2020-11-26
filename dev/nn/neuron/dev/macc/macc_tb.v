`default_nettype none
`include "macc.v"

module macc_tb #(
    parameter PARALLEL_IN=4,
    parameter DATA1_WIDTH = 16,
    parameter DATA1_INT = 2,
    parameter DATA2_WIDTH = 16,
    parameter DATA2_INT = 2,
    parameter ACC_WIDTH = 20,
    parameter DOUT_WIDTH = 32,
    parameter DOUT_INT = 8
)(
    input clk,
    input [PARALLEL_IN*DATA1_WIDTH-1:0] din1,
    input [PARALLEL_IN*DATA2_WIDTH-1:0] din2,
    input en,
    input rst,
    input last,
    output signed [DOUT_WIDTH-1:0] dout,
    output dout_valid
);


macc #(
    .PARALLEL_IN(PARALLEL_IN),
    .DATA1_WIDTH(DATA1_WIDTH),
    .DATA1_INT(DATA1_INT),
    .DATA2_WIDTH(DATA2_WIDTH),
    .DATA2_INT(DATA2_INT),
    .ACC_WIDTH(ACC_WIDTH),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_INT(DOUT_INT)
) macc_inst (
    .clk(clk),
    .din1(din1),
    .din2(din2),
    .en(en),
    .rst(rst),
    .last(last),
    .dout(dout),
    .dout_valid(dout_valid)
);
initial begin
    $dumpfile("trace.vcd");
    $dumpvars();
end


endmodule 
