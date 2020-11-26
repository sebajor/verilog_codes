`timescale 1us/1ns
`default_nettype none
//`define __SIM__

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
