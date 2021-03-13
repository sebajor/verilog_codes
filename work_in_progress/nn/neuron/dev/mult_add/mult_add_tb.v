`default_nettype none
`include "mult_add.v"


module mult_add_tb #(
    parameter PARALLEL_IN = 4,
    parameter DATA1_WIDTH = 16,
    parameter DATA1_INT = 2,
    parameter DATA2_WIDTH = 16,
    parameter DATA2_INT = 2,
    parameter OUT_WIDTH = 32,
    parameter OUT_INT = 16
) (
    input clk,
    input rst, 
    input [DATA1_WIDTH*PARALLEL_IN-1:0] din1,
    input [DATA2_WIDTH*PARALLEL_IN-1:0] din2,
    output [OUT_WIDTH-1:0] dout
);

mult_add #(
    .PARALLEL_IN(PARALLEL_IN),
    .DATA1_WIDTH(DATA1_WIDTH),
    .DATA1_INT(DATA1_INT), 
    .DATA2_WIDTH(DATA2_WIDTH),
    .DATA2_INT(DATA2_INT),
    .OUT_WIDTH(OUT_WIDTH),
    .OUT_INT(OUT_INT)
) mult_add_inst (
    .clk(clk),
    .rst(rst), 
    .din1(din1),
    .din2(din2),
    .dout(dout)
);


initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end

endmodule

