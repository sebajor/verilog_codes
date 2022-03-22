`default_nettype none
`include "dsp48_mult.v"

module mult_tb;

parameter DIN1_WIDTH = 16;
parameter DIN2_WIDTH = 16;
parameter DOUT_WIDTH = 32;

    reg clk;
    reg rst;
    //
    reg [DIN1_WIDTH-1:0] din1;
    reg [DIN2_WIDTH-1:0] din2;
    reg din_valid;
    //
    wire [DOUT_WIDTH-1:0] dout;
    wire dout_valid;

    
dsp48_mult #(
    .DIN1_WIDTH(DIN1_WIDTH),
    .DIN2_WIDTH(DIN2_WIDTH),
    .DOUT_WIDTH(DOUT_WIDTH)
) mult (
    .clk(clk),
    .rst(rst),
    //
    .din1(din1),
    .din2(din2),
    .din_valid(din_valid),
    //
    .dout(dout),
    .dout_valid(dout_valid)
);

initial begin
    rst = 0;
    clk = 1;
    din1 = 1;
    din2 = 2;
    din_valid=0;
end
    

parameter PERIOD = 10;
always begin
    #(PERIOD/2);
    clk = ~clk;    
end

integer i;
initial begin
    for(i=0; i<4; i=i+1)begin
        #(PERIOD);
    end
    din_valid =1;
    for(i=0; i<16; i=i+1)begin
        #(PERIOD);
        din1 = i;
        din2 = i;
    end
    $finish;
end

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end



endmodule
