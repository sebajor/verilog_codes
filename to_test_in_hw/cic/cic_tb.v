`default_nettype none
`include "cic2.v"

module cic_tb #(
    parameter DIN_WIDTH = 16,
    parameter STAGES = 3,     //M  
    parameter DECIMATION = 8, //R
    parameter DIFF_DELAY = 1,  //N=D/R
    //parameter DOUT_WIDTH = DIN_WIDTH + STAGES*$clog2(DECIMATION*DIFF_DELAY)
    parameter DOUT_WIDTH = 32
) (
    input wire clk_in,
    input wire rst,
    input wire signed [DIN_WIDTH-1:0] din,
    //output wire signed [DOUT_WIDTH-1:0] dout,
    output wire signed [31:0] dout_int, //just to use the default struct library
    output wire clk_out,
    input wire [2:0] test_number
);



wire signed [DOUT_WIDTH-1:0] dout;

cic2 #(
    .DIN_WIDTH(16),
    .STAGES(3),     //M  
    .DECIMATION(8), //R
    .DIFF_DELAY(1)  //N=D/R
) cic_inst (
    .clk_in(clk_in),
    .rst(rst),
    .din(din),
    .dout(dout),
    .clk_out(clk_out)
);


assign dout_int = $signed(dout);      //I think there is no problem here...

reg [2:0] test_number_r=0;
always@(posedge clk_in)begin
    test_number_r <= test_number;
end


initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end




endmodule
