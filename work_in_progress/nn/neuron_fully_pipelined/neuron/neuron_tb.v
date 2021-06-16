`default_nettype none
`include "neuron.v"

module neuron_tb #(
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
    parameter WEIGHT_HEAD = "w/w1",
    //activation function
    parameter ACT_WIDTH = 16,
    parameter ACT_INT = 2,
    parameter ACT_OUT_WIDTH = 16,
    parameter ACT_OUT_INT = 2,
    parameter ACTIVATION_TYPE = "relu",
    parameter ACT_FILE = "hdl/sigmoid_hex.mem"
)(
    input wire clk,
    input wire rst,
    input wire signed [PARALLEL*DIN_WIDTH-1:0] din,
    input wire din_valid,
    input wire [ACC_WIDTH+$clog2(PARALLEL)-1:0] bias,
    
    output wire [ACT_OUT_WIDTH-1:0] dout,
    output wire dout_valid
);


neuron #(
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
    .WEIGHT_HEAD(WEIGHT_HEAD),
    .ACT_WIDTH(ACT_WIDTH),
    .ACT_INT(ACT_INT),
    .ACT_OUT_WIDTH(ACT_OUT_WIDTH),
    .ACT_OUT_INT(ACT_OUT_INT),
    .ACTIVATION_TYPE(ACTIVATION_TYPE),
    .ACT_FILE(ACT_FILE)
) neuron_inst (
    .clk(clk),
    .rst(rst),
    .din(din),
    .din_valid(din_valid),
    .bias(bias),
    .dout(dout),
    .dout_valid(dout_valid)
);

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end


endmodule
