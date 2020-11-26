`default_nettype none
`include "delay.v"

module delay_tb;

    parameter DATA_WIDTH=8;
    parameter DEPTH=3;

    reg [DATA_WIDTH-1:0] din;
    reg clk;
    wire [DATA_WIDTH-1:0] dout;

    delay #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) delay_inst (
        .clk(clk),
        .din(din),
        .dout(dout)
    );

    parameter period = 10;
    initial begin
        clk = 1;
        din = 8'h1;
    end
    always begin
        clk = ~clk;
        #(period/2);
    end

    initial begin
        $dumpfile("sim.vcd");
        $dumpvars();
    end
    
    integer i;
    initial begin
        #(period/2)
        for(i=0; i<5; i=i+1)begin
            #(period);
        end
        din = 8'hA;
        for(i=0; i<5; i=i+1)begin
            #(period);
        end
        for(i=0; i<40; i=i+1)begin
            din = i[7:0];
            #(period);
        end
        $finish;
    end


endmodule


