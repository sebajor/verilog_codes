`timescale 1ns/1ps 
`default_nettype none
//`define _init_mem_
`include "bram_infer.v"


module bram_infer_tb #(
    parameter N_ADDR = 256,
    parameter DATA_WIDTH = 16,
    parameter INIT_VALS = "w_1_15.mif"
) (
    input clk,
    input wen,
    input ren,
    input [$clog2(N_ADDR)-1:0] wadd,
    input [$clog2(N_ADDR)-1:0] radd,
    input [DATA_WIDTH-1:0]       win,
    output reg [DATA_WIDTH-1:0]  wout
);


bram_infer #(
    .N_ADDR(N_ADDR),
    .DATA_WIDTH(DATA_WIDTH),
    .INIT_VALS(INIT_VALS) 
) bram_infer_inst (
    .clk(clk),
    .wen(wen),
    .ren(ren),
    .wadd(wadd),
    .radd(radd),
    .win(win),
    .wout(wout)
);


initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end

endmodule
