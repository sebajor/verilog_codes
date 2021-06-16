`default_nettype none
`include "includes.v"

module neuron #(
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
    parameter ACT_OUT_INT = 15,
    parameter ACTIVATION_TYPE = "relu",
    parameter ACT_FILE = "hdl/sigmoid_hex.mem"
)(
    input wire clk,
    input wire rst,
    input wire signed [PARALLEL*DIN_WIDTH-1:0] din,
    input wire din_valid,
    input wire [ACC_WIDTH+$clog2(PARALLEL)-1:0] bias,        //this should be hardcoded
    
    output wire [ACT_OUT_WIDTH-1:0] dout,
    output wire dout_valid
);

wire signed [$clog2(PARALLEL)+ACC_WIDTH-1:0] acc_out;
wire acc_valid;

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
) perceptron_inst (
    .clk(clk),
    .rst(rst),
    .din(din),
    .din_valid(din_valid),
    .acc_out(acc_out),
    .acc_valid(acc_valid)
);

reg signed [$clog2(PARALLEL)+ACC_WIDTH-1:0] acc_bias;
reg bias_valid;
always@(posedge clk)begin
    bias_valid <= acc_valid;
    if(acc_valid)
        acc_bias <= $signed(acc_out)+$signed(bias);
end



localparam ACC_INT = $clog2(PARALLEL)+ACC_WIDTH-ACC_POINT;
localparam ACT_POINT = ACT_WIDTH-ACT_INT;

wire [ACT_WIDTH-1:0] percep_cast;
wire percept_cast_valid;

signed_cast #(
    .DIN_WIDTH($clog2(PARALLEL)+ACC_WIDTH),
    .DIN_POINT(ACC_POINT),
    .DOUT_WIDTH(ACT_WIDTH),
    .DOUT_POINT(ACT_POINT)
)signed_cast_inst (
    .clk(clk), 
    .din(acc_bias),
    .din_valid(bias_valid),
    .dout(percep_cast),
    .dout_valid(percept_cast_valid)
);


activation_function #(
    .DIN_WIDTH(ACT_WIDTH),
    .DIN_INT(ACT_INT),
    .DOUT_WIDTH(ACT_OUT_WIDTH),
    .DOUT_INT(ACT_OUT_INT),
    .ACTIVATION_TYPE(ACTIVATION_TYPE),
    .FILENAME(ACT_FILE)
) activation_inst (
    .clk(clk),
    .din(percep_cast),
    .din_valid(percept_cast_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);


endmodule
