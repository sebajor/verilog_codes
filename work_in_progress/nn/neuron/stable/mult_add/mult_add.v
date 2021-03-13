`default_nettype none 
`include "../../stable/parallel_mult/parallel_mult.v"
`include "../../stable/adder_tree/adder_tree.v"
`include "../../stable/downsize/downsize.v"

/* parallel multipliying and then use a adder tree
*/

module mult_add #(
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
    localparam MULT_WIDTH = DATA1_WIDTH+DATA2_WIDTH;
    localparam MULT_INT = DATA1_INT+DATA2_INT;

    wire [MULT_WIDTH*PARALLEL_IN-1:0] mult_out;
    
    //delay 1
    parallel_mult #(
        .PARALLEL_IN(PARALLEL_IN),
        .DATA1_WIDTH(DATA1_WIDTH),
        .DATA1_INT(DATA1_INT),
        .DATA2_WIDTH(DATA2_WIDTH),
        .DATA2_INT(DATA2_INT),
        .OUT_WIDTH(MULT_WIDTH),
        .OUT_INT(MULT_INT)
    ) parallel_mult_inst (
        .clk(clk),
        .din1(din1),
        .din2(din2),
        .dout(mult_out)
    );

    localparam RESIZE = OUT_WIDTH-$clog2(PARALLEL_IN);
    wire [RESIZE*PARALLEL_IN-1:0] mult_sized;
    //delay 1
    downsize #(
        .PARALLEL_IN(PARALLEL_IN),
        .DIN_WIDTH(MULT_WIDTH),
        .DOUT_WIDTH(RESIZE)
    ) downsize_inst (
        .clk(clk),
        .din(mult_out),
        .dout(mult_sized)
    );


    //delay clog2(parallel_in)
    adder_tree #(
        .PARALLEL(PARALLEL_IN),
        .DATA_WIDTH(RESIZE)
    ) adder_tree_inst (
        .clk(clk),
        .din(mult_sized),
        .dout(dout)
    );



endmodule 


