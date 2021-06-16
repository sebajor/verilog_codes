`default_nettype none
`timescale 1ns / 1ps
`include "delay_tree.v"

module delay_tree_tb;

parameter DIN_WIDTH = 8;
parameter STAGES = 4;   //2**4 outputs

parameter PERIOD = 10;

reg clk=0, din_valid=0;
reg [DIN_WIDTH-1:0] din=0;

wire [DIN_WIDTH-1:0] dout0, dout1, dout2, dout3, dout4, dout5, dout6,dout7;
wire dout_valid;

delay_tree #(
    .DIN_WIDTH(DIN_WIDTH),
    .STAGES(STAGES)
) delay_tree_inst(
    .clk(clk),
    .din(din),
    .din_valid(din_valid),
    .dout({dout0,dout1,dout2,dout3,dout4,dout5,dout6,dout7}),
    .dout_valid(dout_valid)
);

always begin
    clk = ~clk;
    #(PERIOD/2);
end

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end


integer i=0;
initial begin
    #(5*PERIOD);
    din_valid = 1;
    for(i=0; i<30; i=i+1)begin
        din = i;
        #(PERIOD);
    end
    $finish();
end





endmodule
