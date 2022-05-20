`include "adder_tree.v"
`include "../delay/delay.v"

module adder_test;
    parameter DATA_WIDTH = 8;   
    parameter PARALLEL = 9;

    reg [DATA_WIDTH*PARALLEL-1:0] din=0;
    reg clk;
    wire [DATA_WIDTH+$clog2(PARALLEL)-1:0] dout;
    reg din_valid =0;
    wire dout_valid;
    adder_tree #(
        .DATA_WIDTH(DATA_WIDTH),
        .PARALLEL(PARALLEL)
    ) adder_tree(
        .clk(clk),
        .din(din),
        .din_valid(din_valid),
        .dout(dout),
        .dout_valid(dout_valid)
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
        $dumpfile("traces.vcd");
        $dumpvars();
    end
    initial begin
        //(5);
        #(period);
        for(i=20; i>0;i=i-1)begin
            din_valid = 1;
            din = {PARALLEL{i[7:0]}};
            #(period);
            if(dout_valid)
                $display ("%d", dout);
        end
        $finish;
    end
endmodule
