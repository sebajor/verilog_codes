`default_nettype none
`include "includes.v"
`include "agc_least_squares.v"

module agc_least_squares_tb #(
    parameter DIN_WIDTH =8,     //ufix8_7
    parameter DELAY_LINE = 32,
    parameter REFRESH_CYCLES = 1024,
    parameter ERROR_POINT = 14,
    parameter GAIN_WIDTH = 12,
    parameter GAIN_POINT = 10,
    //limits to mantain the gain in a certain range
    parameter GAIN_HIGH_LIM = 32,   
    parameter GAIN_LOW_LIM = 4
) (
    input wire clk,
    input wire rst,

    input wire signed [DIN_WIDTH-1:0] din,
    input wire din_valid,

    input wire [2*DIN_WIDTH-1:0] ref_pow,   //ufix16_14
    input wire [2*DIN_WIDTH-1:0] error_coef, //ufix(2*din_width)_error_point

    output wire [GAIN_WIDTH-1:0] gain,
    output wire gain_valid
);


agc_least_squares #(
    .DIN_WIDTH(),
    .DELAY_LINE(),
    .REFRESH_CYCLES(),
    .ERROR_POINT(),
    .GAIN_WIDTH(),
    .GAIN_POINT(),
    .GAIN_HIGH_LIM(),
    .GAIN_LOW_LIM()
) agc_least_squares_inst (
    .clk(clk),
    .rst(rst),
    .din(din),
    .din_valid(din_valid),
    .ref_pow(ref_pow),  
    .error_coef(error_coef),
    .gain(gain),
    .gain_valid(gain_valid)
);

endmodule
