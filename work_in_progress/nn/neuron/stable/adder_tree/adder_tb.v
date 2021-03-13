`include "adder_tree.v"
module adder_test;
    parameter DATA_WIDTH = 8;   
    parameter PARALLEL = 8;

    reg [DATA_WIDTH*PARALLEL-1:0] din;
    reg clk;
    wire [DATA_WIDTH+$clog2(PARALLEL)-1:0] dout;
    adder_tree #(
        .DATA_WIDTH(DATA_WIDTH),
        .PARALLEL(PARALLEL)
    ) adder_tree(
        .clk(clk),
        .din(din),
        .dout(dout)
    );
    
    initial begin
        clk =1;
        din = {PARALLEL{8'd5}};
    end
    parameter period=10;
    always begin
        #(5);
        clk = ~clk; 
    end
    integer i;
    initial begin
        $dumpfile("data.vcd");
        $dumpvars();
    end
    initial begin
        //(5);
        #(period);
        for(i=0; i<20;i=i+1)begin
            din = {PARALLEL{i[7:0]}};
            #(period);
            $display ("%x", dout);
        end
        $finish;
    end
endmodule
