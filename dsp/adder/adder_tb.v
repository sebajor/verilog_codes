`default_nettype none
`timescale 1ns / 1ps
//`include "adder.v"

module adder_tb #(
    parameter DIN_WIDTH = 10,
    parameter DATA_TYPE = "unsigned"
)(
    input wire clk,
    input wire [DIN_WIDTH-1:0] din0, din1,
    input wire din_valid,
    output wire [2*DIN_WIDTH-1:0] dout,
    output wire dout_valid
);

adder #(
    .DIN_WIDTH(DIN_WIDTH),
    .DATA_TYPE(DATA_TYPE)
) adder_inst (
    .clk(clk),
    .din0(din0),
    .din1(din1),
    .din_valid(din_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);
endmodule
