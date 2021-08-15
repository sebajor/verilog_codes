`timescale 1ns/1ps 
`default_nettype none
//`define _init_mem_


module rom #(
    parameter N_ADDR = 256,
    parameter DATA_WIDTH = 16,
    parameter INIT_VALS = "w_1_15.mif"
) (
    input wire clk,
    input wire ren,
    input wire [$clog2(N_ADDR)-1:0] radd,
    output reg [DATA_WIDTH-1:0]  wout
);
    reg [DATA_WIDTH-1:0] mem [N_ADDR-1:0];
    initial begin
        $readmemh(INIT_VALS, mem);    //read bnary file and initialize
    end

    always@(posedge clk)begin
        if(ren)begin
            wout <= mem[radd];
        end
    end
   
endmodule
