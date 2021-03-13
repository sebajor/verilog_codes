`timescale 1us/1ns
`default_nettype none
//`include "single_mult/single_mult.v"

`define __SIM__


module parallel_mult #(
    parameter PARALLEL_IN = 4,
    parameter DATA1_WIDTH = 16,
    parameter DATA1_INT = 2,
    parameter DATA2_WIDTH = 16,
    parameter DATA2_INT = 2,
    parameter OUT_WIDTH = 32,
    parameter OUT_INT = 4
) (
    input clk,
    input [DATA1_WIDTH*PARALLEL_IN-1:0] din1,
    input [DATA2_WIDTH*PARALLEL_IN-1:0] din2,
    output [OUT_WIDTH*PARALLEL_IN-1:0] dout
);
    //localparam FULL_SIZE = DATA1_WIDTH+DATA2_WIDTH;
    //localparam FULL_INT = DATA1_INT+DATA2_WIDTH;

    //wire [FULL_SIZE*PARALLEL_IN-1:0] full_mult;

    //no estoy muy seguro de que le este pasando los parametros al simular....
    genvar i;
    generate
        for(i=0;i<PARALLEL_IN; i=i+1)begin
            single_mult #(
                .DATA1_WIDTH(DATA1_WIDTH),
                .DATA1_INT(DATA1_INT),
                .DATA2_WIDTH(DATA2_WIDTH),
                .DATA2_INT(DATA2_INT),
                .OUT_WIDTH(OUT_WIDTH),
                .OUT_INT(OUT_INT)
            ) sing_mult(
                .clk(clk),
                .din1(din1[DATA1_WIDTH*i+:DATA1_WIDTH]),
                .din2(din2[DATA2_WIDTH*i+:DATA2_WIDTH]),
                .dout(dout[OUT_WIDTH*i+:OUT_WIDTH])
            );
        end
    endgenerate


`ifdef __SIM__
    wire [DATA1_WIDTH-1:0] d1;
    wire [DATA2_WIDTH-1:0] d2;
    wire [OUT_WIDTH-1:0] dout_t;
    assign d1 = din1[2*DATA1_WIDTH-1:DATA1_WIDTH];
    assign d2 = din2[2*DATA2_WIDTH-1:DATA2_WIDTH];
    assign dout_t = dout[2*OUT_WIDTH-1:OUT_WIDTH];
    initial begin
        $dumpfile("sim.vcd");
        $dumpvars(1, parallel_mult);
    end
`endif

endmodule 

module single_mult #(
    parameter DATA1_WIDTH = 16,
    parameter DATA1_INT = 4,
    parameter DATA2_WIDTH = 16,
    parameter DATA2_INT = 4,
    parameter OUT_WIDTH = 32,
    parameter OUT_INT = 8
)(
    input clk,
    input [DATA1_WIDTH-1:0] din1,
    input [DATA2_WIDTH-1:0] din2,
    output [OUT_WIDTH-1:0] dout
);
    localparam FULL_WIDTH = DATA1_WIDTH+DATA2_WIDTH; //quizas necesita 1 bit mas..
    localparam FULL_INT = DATA1_INT+DATA2_INT;
    reg signed [DATA1_WIDTH+DATA2_WIDTH-1:0] full_mult=0;

    always@(posedge clk)begin
        full_mult = $signed(din1)*$signed(din2);
    end
    
    //truncate the output in the output boundaries
    localparam OUT_POINT = OUT_WIDTH-OUT_INT;
    
    assign dout = {full_mult[FULL_WIDTH-1], full_mult[FULL_WIDTH-FULL_INT+:OUT_INT-1],
        full_mult[FULL_WIDTH-FULL_INT-1-:OUT_POINT]}; 
/*
    `ifdef __SIM__
        initial begin
            $dumpfile("sim.vcd");
            $dumpvars(1, single_mult);
        end
    `endif
*/

endmodule



