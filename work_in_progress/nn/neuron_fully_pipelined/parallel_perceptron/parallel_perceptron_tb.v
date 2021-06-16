`default_nettype none
`include "parallel_perceptron.v"

module parallel_perceptron_tb #(
    parameter PARALLEL = 4,
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 15,
    parameter WEIGTH_WIDTH = 16,
    parameter WEIGTH_POINT = 15,
    parameter WEIGTH_NUMB = 64,
    parameter BIAS_WIDTH = 16,
    parameter BIAS_POINT = 15,

    //accumulation parameters
    parameter ACC_WIDTH = 48,
    parameter ACC_POINT = 30,

    //weight file
    parameter WEIGHT_HEAD = "w/w1"
) (
    input wire clk,
    input wire rst,
    input wire signed [PARALLEL*DIN_WIDTH-1:0] din,
    input wire din_valid,

    output wire signed [$clog2(PARALLEL)+ACC_WIDTH-1:0] acc_out,
    output wire acc_valid
);


parallel_perceptron #(
    .PARALLEL(PARALLEL),
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .WEIGTH_WIDTH(WEIGTH_WIDTH),
    .WEIGTH_POINT(WEIGTH_POINT),
    .WEIGTH_NUMB(WEIGTH_NUMB),
    .BIAS_WIDTH(BIAS_WIDTH),
    .BIAS_POINT(BIAS_POINT),
    .ACC_WIDTH(ACC_WIDTH),
    .ACC_POINT(ACC_POINT),
    .WEIGHT_HEAD(WEIGHT_HEAD)
) parallel_perceptron_inst (
    .clk(clk),
    .rst(rst),
    .din(din),
    .din_valid(din_valid),
    .acc_out(acc_out),
    .acc_valid(acc_valid)
);


initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end

endmodule
