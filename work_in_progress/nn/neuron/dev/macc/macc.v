`include "../../stable/mult_add/mult_add.v"
`include "../../stable/delay/delay.v"
`include "../../stable/accumulator/sig_acc.v"
`default_nettype none


// the error appears in the third fraction value
// the data when representing in 1o base


module macc #(
    parameter PARALLEL_IN=4,
    parameter DATA1_WIDTH = 16,
    parameter DATA1_INT = 2,
    parameter DATA2_WIDTH = 16,
    parameter DATA2_INT = 2,
    parameter ACC_WIDTH = 20,
    parameter DOUT_WIDTH = 32,
    parameter DOUT_INT = 14
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

    localparam MADD_INT = $clog2(PARALLEL_IN)+DATA1_INT+DATA2_INT;
    
    wire signed [ACC_WIDTH-1:0] madd_out;
    
    mult_add #(
        .PARALLEL_IN(PARALLEL_IN),
        .DATA1_WIDTH(DATA1_WIDTH),
        .DATA1_INT(DATA1_INT),
        .DATA2_WIDTH(DATA2_WIDTH),
        .DATA2_INT(DATA2_INT),
        .OUT_WIDTH(ACC_WIDTH),
        .OUT_INT(4) //not used now...
    ) mult_add_inst (
        .clk(clk),
        .rst(rst),  //not used here..
        .din1(din1),
        .din2(din2),
        .dout(madd_out)
    );

    wire [2:0] d_control;
    localparam MADD_DELAY = 2+$clog2(PARALLEL_IN)-1;//check
    delay #(
        .DATA_WIDTH(3),
        .DEPTH(MADD_DELAY)
    ) delay_inst (
        .clk(clk),
        .din({en, rst, last}),
        .dout(d_control)
    );

    sig_acc #(
        .DIN_WIDTH(ACC_WIDTH),
        .DIN_INT(MADD_INT),
        .DOUT_WIDTH(DOUT_WIDTH),
        .DOUT_INT(DOUT_INT)
    ) sig_acc (
        .clk(clk),
        .din(madd_out),
        .en(d_control[2]),
        .rst(d_control[1]),
        .last(d_control[0]),
        .dout(dout),
        .dout_valid(dout_valid)
    );


endmodule 

