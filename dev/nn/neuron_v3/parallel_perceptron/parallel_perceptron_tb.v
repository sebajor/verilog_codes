`default_nettype none
`include "parallel_perceptron.v"


module parallel_perceptron_tb #(
    //macc parameters
    parameter PARALLEL = 8,
    parameter DIN_WIDTH = 8,
    parameter DIN_INT = 1,
    parameter WEIGHT_ADDRS = 64,  
    parameter WEIGHT_WIDTH = 16,
    parameter WEIGHT_INT = 1,
    parameter SUM_IN_WIDTH = 16,
    parameter SUM_IN_INT = 2,
    parameter ACC_OUT_WIDTH = 32,
    parameter ACC_OUT_INT = 10,
    //
    parameter BIAS_WIDTH = 10,
    parameter BIAS_INT = 4,
    //activation parameters
    parameter ACTIVATION_TYPE = "relu",
    parameter ACT_IN_WIDTH = 16,
    parameter ACT_IN_INT = 4,
    parameter ACT_OUT_WIDTH = 8,
    parameter ACT_OUT_INT = 4,      //I should normalize the output to (-1,1)??
    parameter FILENAME = "/home/seba/Workspace/verilog_codes/dev/nn/neuron_v3/activation/sigmoid_hex.mem"
) (
    //macc inputs 
    input wire clk,
    input wire rst,
    input wire signed [PARALLEL*DIN_WIDTH-1:0] din,
    input wire signed [PARALLEL*WEIGHT_WIDTH-1:0] weight,
    input wire din_valid,
    //bias input
    input wire [BIAS_WIDTH-1:0] bias,
    //activation output
    output wire [ACT_OUT_WIDTH-1:0] dout,
    output wire dout_valid
);


parallel_perceptron #(
    .PARALLEL(PARALLEL),
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_INT(DIN_INT),
    .WEIGHT_ADDRS(WEIGHT_ADDRS),  
    .WEIGHT_WIDTH(WEIGHT_WIDTH),
    .WEIGHT_INT(WEIGHT_INT),
    .SUM_IN_WIDTH(SUM_IN_WIDTH),
    .SUM_IN_INT(SUM_IN_INT),
    .ACC_OUT_WIDTH(ACC_OUT_WIDTH),
    .ACC_OUT_INT(ACC_OUT_INT),
    .BIAS_WIDTH(BIAS_WIDTH),
    .BIAS_INT(BIAS_INT),
    .ACTIVATION_TYPE(ACTIVATION_TYPE),
    .ACT_IN_WIDTH(ACT_IN_WIDTH),
    .ACT_IN_INT(ACT_IN_INT),
    .ACT_OUT_WIDTH(ACT_OUT_WIDTH),
    .ACT_OUT_INT(ACT_OUT_INT),      //I should normalize the output to (-1(),1)??
    .FILENAME(FILENAME)
) parallel_perceptron_inst (
    //macc inputs 
    .clk(clk),
    .rst(rst),
    .din(din),
    .weight(weight),
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
