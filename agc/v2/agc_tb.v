`default_nettype none
`include "agc.v"

module agc #(
    parameter DIN_WIDTH =8,     //ufix8_7
    parameter DELAY_LINE = 32,
    parameter REFRESH_CYCLES = 1024,
    parameter GAIN_WIDTH = 12,
    parameter GAIN_HIGH_LIM = 32,
    parameter GAIN_LOW_LIM = 4 
) (
    input wire clk,
    input wire rst,

    input wire signed [DIN_WIDTH-1:0] din,
    input wire din_valid,

    input wire [2*DIN_WIDTH-1:0] ref_pow,   //ufix16_14
    input wire [2*DIN_WIDTH-1:0] error_coef,

    output wire [GAIN_WIDTH-1:0] gain  
);


agc #(
    .DIN_WIDTH(DIN_WIDTH),
    .DELAY_LINE(DELAY_LINE),
    .REFRESH_CYCLES(REFRESH_CYCLES),
    .GAIN_WIDTH(GAIN_WIDTH),
    .GAIN_HIGH_LIM(GAIN_HIGH_LIM),
    .GAIN_LOW_LIM(GAIN_LOW_LIM)
) agc_tb (
    .clk(clk),
    .rst(rst),
    .din(din),
    .din_valid(din_valid),
    .ref_pow(ref_pow),  
    .error_coef(error_coef),
    .gain(gain)
);



endmodule
