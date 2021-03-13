`default_nettype none
`include "acc.v"

module acc_tb #(
    parameter DIN_WIDTH = 16,
    parameter DIN_INT= 8,
    parameter DOUT_WIDTH = 32,
    parameter DOUT_INT = 16 
) (
    input wire clk,
    input wire rst,
    input wire signed [DIN_WIDTH-1:0] din,
    input wire din_valid,
    input wire din_sof,
    input wire din_eof,
    output wire signed [DOUT_WIDTH-1:0] dout,
    output wire dout_valid 
);

acc #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_INT(DIN_INT),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_INT(DOUT_INT) 
) acc_inst (
    .clk(clk),
    .rst(rst),
    .din(din),
    .din_valid(din_valid),
    .din_sof(din_sof),
    .din_eof(din_eof),
    .dout(dout),
    .dout_valid(dout_valid)
);

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end


endmodule 
