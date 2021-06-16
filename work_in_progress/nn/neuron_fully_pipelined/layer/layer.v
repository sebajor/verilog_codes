`default_nettype none
`include "includes.v"


module layer #(
    parameter NUM_NEURON = 4,       //number of neurons of this layer
    parameter PARALLEL = 4,         //simoultaneous inputs
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 15,
    parameter WEIGTH_WIDTH = 16,
    parameter WEIGTH_POINT = 15,
    parameter WEIGTH_NUMB = 64,
    //accumulation parameters
    parameter ACC_WIDTH = 48,
    parameter ACC_POINT = 30,
    //weight file
    parameter WEIGHT_HEAD = "w",
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
    input wire [(ACC_WIDTH+$clog2(PARALLEL))*NUM_NEURON-1:0] bias,        //this should be hardcoded
    
    output wire [ACT_OUT_WIDTH*NUM_NEURON-1:0] dout,
    output wire [NUM_NEURON-1:0] dout_valid
);

//As all the neuron share the inputs we have to replicate them

wire delay_valid;
wire [PARALLEL*NUM_NEURON*DIN_WIDTH-1:0] din_neuron;

delay_tree #(
    .DIN_WIDTH(PARALLEL*DIN_WIDTH),
    .STAGES($clog2(NUM_NEURON)+1)    //in each stage we duplicate the width
) delay_tree_inst (
    .clk(clk),
    .din(din),
    .din_valid(din_valid),
    .dout(din_neuron),
    .dout_valid(delay_valid)
);

//instantiate each neuron
genvar i;
localparam BIAS_WIDTH = ACC_WIDTH+$clog2(PARALLEL);
localparam WEIGHT_SUBFOLD = "/w";
generate 
    for(i=0; i<NUM_NEURON; i=i+1) begin:loop
        localparam integer temp = 48+i;
        localparam WEIGHT_LOC = {WEIGHT_HEAD, WEIGHT_SUBFOLD, temp};
        neuron #(
            .PARALLEL(PARALLEL),
            .DIN_WIDTH(DIN_WIDTH), 
            .DIN_POINT(DIN_POINT),
            .WEIGTH_WIDTH(WEIGTH_WIDTH),
            .WEIGTH_POINT(WEIGTH_POINT),
            .WEIGTH_NUMB(WEIGTH_NUMB),
            .ACC_WIDTH(ACC_WIDTH),
            .ACC_POINT(ACC_POINT),
            .WEIGHT_HEAD(WEIGHT_LOC),
            .ACT_WIDTH(ACT_WIDTH),
            .ACT_INT(ACT_INT),
            .ACT_OUT_WIDTH(ACT_OUT_WIDTH),
            .ACT_OUT_INT(ACT_OUT_INT),
            .ACTIVATION_TYPE(ACTIVATION_TYPE),
            .ACT_FILE(ACT_FILE)
        ) neuron_inst (
            .clk(clk),
            .rst(rst),
            .din(din_neuron[DIN_WIDTH*PARALLEL*i+:DIN_WIDTH*PARALLEL]),
            .din_valid(delay_valid),
            .bias(bias[BIAS_WIDTH*i+:BIAS_WIDTH]),
            .dout(dout[ACT_OUT_WIDTH*i+:ACT_OUT_WIDTH]),
            .dout_valid(dout_valid[i])
        );
    end
endgenerate

endmodule

