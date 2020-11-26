`timescale 1ns/1ps 
`default_nettype none
//`ìnclude "definitions.v"
//`define __SIM__
`define _pretrained_


module Weight_mem #(
    parameter N_WEIGHT = 256,
    parameter DATA_WIDTH = 16,
    parameter WEIGHT_FILE = "w_1_15.mif"
) (
    input clk,
    input wen,
    input ren,
    input [$clog2(N_WEIGHT)-1:0] wadd,
    input [$clog2(N_WEIGHT)-1:0] radd,
    input [DATA_WIDTH-1:0]       win,
    output reg [DATA_WIDTH-1:0]  wout
);
    reg [DATA_WIDTH-1:0] mem [N_WEIGHT-1:0];
    `ifdef _pretrained_
        initial begin
            $readmemh(WEIGHT_FILE, mem);    //read bnary file and initialize
        end
    `else
		integer i;
		initial begin
			for(i=0; i<N_WEIGHT; i=i+1)begin
				mem[i] = 0;
			end
		end
        always@(posedge clk)begin
            if(wen)begin
                mem[wadd] <= win;
            end
        end
    `endif

    always@(posedge clk)begin
        if(ren)begin
            wout <= mem[radd];
        end
    end
   

   /* 
    `ifdef __SIM__
    initial begin
        $dumpfile("sim.vcd");
        $dumpvars(0, Weight_mem);
    end
    `endif

    */
endmodule
