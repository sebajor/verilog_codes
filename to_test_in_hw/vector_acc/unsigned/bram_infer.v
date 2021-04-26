`timescale 1ns/1ps 
`default_nettype none


module bram_infer #(
    parameter N_ADDR = 256,
    parameter DATA_WIDTH = 16
) (
    input wire clk,
    input wire wen,
    input wire ren,
    input wire [$clog2(N_ADDR)-1:0] wadd,
    input wire [$clog2(N_ADDR)-1:0] radd,
    input wire [DATA_WIDTH-1:0]       win,
    output reg [DATA_WIDTH-1:0]  wout
);
    reg [DATA_WIDTH-1:0] mem [N_ADDR-1:0];
    integer i;
    initial begin
        for(i=0; i<N_ADDR; i=i+1)begin
            mem[i] = 0;
        end
    end
    always@(posedge clk)begin
        if(wen)begin
            mem[wadd] <= win;
        end
    end

    always@(posedge clk)begin
        if(ren)begin
            wout <= mem[radd];
        end
    end
   
endmodule
