`default_nettype none
`include "single_perceptron.v"

/*
This perceptron just have one input (not multiple, like parallel pereptron)
the main difference is that we only utilize one multiplier and dont have
an adder tree previoud the accumulator
*/

module single_perceptron_tb #(
    parameter DIN_WIDTH = 8,
    parameter DIN_INT = 1,
    parameter WEIGHT_WIDTH = 16,
    parameter WEIGHT_INT = 2,
    parameter WEIGHT_ADDRS = 512,
    parameter BIAS_WIDTH = 16,
    parameter BIAS_INT = 4,
    //accumulator 
    parameter ACC_IN_WIDTH = 16,
    parameter ACC_IN_INT = 2,
    parameter ACC_OUT_WIDTH = 32,
    parameter ACC_OUT_INT = 10,

    //activation
    parameter ACTIVATION_TYPE = "relu",
    parameter ACT_IN_WIDTH = 16,
    parameter ACT_IN_INT = 5,
    parameter ACT_OUT_WIDTH = 8,
    parameter ACT_OUT_INT = 4,
    parameter FILENAME = "/home/seba/Workspace/verilog_codes/dev/nn/neuron_v3/activation/sigmoid_hex.mem"
) (
    input wire clk,
    input wire rst,
    
    input wire signed [DIN_WIDTH-1:0] din,
    input wire din_valid,
    input wire signed [WEIGHT_WIDTH-1:0] weight,
    input wire signed [BIAS_WIDTH-1:0] bias,

    output wire signed [ACT_OUT_WIDTH-1:0] dout,
    output wire dout_valid
);


single_perceptron #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_INT(DIN_INT),
    .WEIGHT_WIDTH(WEIGHT_WIDTH),
    .WEIGHT_INT(WEIGHT_INT),
    .WEIGHT_ADDRS(WEIGHT_ADDRS),
    .BIAS_WIDTH(BIAS_WIDTH),
    .BIAS_INT(BIAS_INT),
    //accumulator 
    .ACC_IN_WIDTH(ACC_IN_WIDTH),
    .ACC_IN_INT(ACC_IN_INT),
    .ACC_OUT_WIDTH(ACC_OUT_WIDTH),
    .ACC_OUT_INT(ACC_OUT_INT),

    //activation
    .ACTIVATION_TYPE(ACTIVATION_TYPE),
    .ACT_IN_WIDTH(ACT_IN_WIDTH),
    .ACT_IN_INT(ACT_IN_INT),
    .ACT_OUT_WIDTH(ACT_OUT_WIDTH),
    .ACT_OUT_INT(ACT_OUT_INT),
    .FILENAME(FILENAME)
) single_perceptron_int (
    .clk(clk),
    .rst(rst),
    .din(din),
    .din_valid(din_valid),
    .weight(weight),
    .bias(bias),
    .dout(dout),
    .dout_valid(dout_valid)
);

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end



endmodule

