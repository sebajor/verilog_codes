`default_nettype none

`include "parallel_macc.v"

module parallel_macc_tb #(
    parameter PARALLEL = 8,
    parameter DIN_WIDTH = 8,
    parameter DIN_INT = 1,
    parameter WEIGHT_ADDRS = 64,  
    parameter WEIGHT_WIDTH = 16,
    parameter WEIGHT_INT = 3,
    parameter SUM_IN_WIDTH = 16,
    parameter SUM_IN_INT = 4,
    parameter ACC_OUT_WIDTH = 32,
    parameter ACC_OUT_INT = 10
) (
    input wire clk,
    input wire rst,
    //input wire [$clog2(WEIGHT_ADDRS):0] weight_addr,

    input wire signed [PARALLEL*DIN_WIDTH-1:0] din,
    input wire signed [PARALLEL*WEIGHT_WIDTH-1:0] weight,
    input wire din_valid,
    
    output wire signed [ACC_OUT_WIDTH-1:0] dout,
    output wire dout_valid
);


parallel_macc #(
    .PARALLEL(PARALLEL),
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_INT(DIN_INT),
    .WEIGHT_ADDRS(WEIGHT_ADDRS),  
    .WEIGHT_WIDTH(WEIGHT_WIDTH),
    .WEIGHT_INT(WEIGHT_INT),
    .SUM_IN_WIDTH(SUM_IN_WIDTH),
    .SUM_IN_INT(SUM_IN_INT),
    .ACC_OUT_WIDTH(ACC_OUT_WIDTH),
    .ACC_OUT_INT(ACC_OUT_INT)
) parallel_macc_inst (
    .clk(clk),
    .rst(rst),
    .din(din),
    .weight(weight),
    .din_valid(din_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end



endmodule
