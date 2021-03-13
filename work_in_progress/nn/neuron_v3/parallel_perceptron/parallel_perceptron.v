`default_nettype none
`include "/home/seba/Workspace/verilog_codes/dev/nn/neuron_v3/parallel_macc/parallel_macc.v"
//`include "/home/seba/Workspace/verilog_codes/dev/nn/neuron_v3/signed_cast/signed_cast.v"
`include "/home/seba/Workspace/verilog_codes/dev/nn/neuron_v3/activation/activation.v"



/* parallel input perceptron

    parallel_macc -> add  bias-> signed_cast -> activation function 

After the macc we add the bias value and then cast that to match the
size of the activation function (remember it could be mase using a 
lut, so the input bitsize match the lut address
*/



module parallel_perceptron #(
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
    parameter ACT_IN_INT = 5,
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

//macc ouputs
wire signed [ACC_OUT_WIDTH-1:0] macc_dout;
wire macc_dout_valid;


parallel_macc #(
    .PARALLEL(PARALLEL),
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_INT(DIN_INT),
    .WEIGHT_ADDRS(WEIGHT_ADDRS),  
    .WEIGHT_WIDTH(WEIGHT_WIDTH),
    .WEIGHT_INT(WEIGHT_INT),
    .SUM_IN_WIDTH(SUM_IN_WIDTH),
    .SUM_IN_INT(SUM_IN_INT),
    .ACC_OUT_WIDTH(ACC_OUT_WIDTH),
    .ACC_OUT_INT(ACC_OUT_INT)
) parallel_macc_inst (
    .clk(clk),
    .rst(rst),
    .din(din),
    .weight(weight),
    .din_valid(din_valid),
    .dout(macc_dout),
    .dout_valid(macc_dout_valid)
);

localparam MACC_POINT = ACC_OUT_WIDTH-ACC_OUT_INT;
localparam BIAS_POINT = BIAS_WIDTH-BIAS_INT;
wire signed [ACC_OUT_WIDTH-1:0] bias_align;

/*
generate
    if(BIAS_POINT<MACC_POINT)
        assign bias_align = (bias <<<(MACC_POINT-BIAS_POINT));
    else
        assign bias_align = (bias >>>(BIAS_POINT-MACC_POINT));
endgenerate
*/

signed_cast #(
    .PARALLEL(1),
    .DIN_WIDTH(BIAS_WIDTH),
    .DIN_INT(BIAS_INT),
    .DOUT_WIDTH(ACC_OUT_WIDTH),
    .DOUT_INT(ACC_OUT_INT)
) bias_casting (
    .clk(clk),
    .din(bias),
    .din_valid(1'b1),
    .dout(bias_align),
    .dout_valid()
);




//adder
reg signed [ACC_OUT_WIDTH:0] add_out_r=0;
reg add_out_valid_r=0;
wire signed [ACC_OUT_WIDTH:0] add_out;
wire add_out_valid;
assign add_out = add_out_r;
assign add_out_valid = add_out_valid_r;

always@(posedge clk)begin
    if(macc_dout_valid)begin
        add_out_r <= $signed(bias_align)+$signed(macc_dout);
        add_out_valid_r <= 1;
    end
    else begin
        add_out_r <= add_out;
        add_out_valid_r <= 0;
    end
end



//cast
wire [ACT_IN_WIDTH-1:0] act_in;
wire act_valid;

signed_cast #(
    .PARALLEL(1),
    .DIN_WIDTH(ACC_OUT_WIDTH+1),
    .DIN_INT(ACC_OUT_INT+1),
    .DOUT_WIDTH(ACT_IN_WIDTH),
    .DOUT_INT(ACT_IN_INT)
) add_out_casting (
    .clk(clk),
    .din(add_out),
    .din_valid(add_out_valid),
    .dout(act_in),
    .dout_valid(act_valid)
);

//activation function
activation_function #(
    .DIN_WIDTH(ACT_IN_WIDTH),
    .DIN_INT(ACT_IN_INT),
    .DOUT_WIDTH(ACT_OUT_WIDTH),
    .DOUT_INT(ACT_OUT_INT),
    .ACTIVATION_TYPE(ACTIVATION_TYPE),
    .FILENAME(FILENAME)
) act_func_inst (
    .clk(clk),
    .din(act_in),
    .din_valid(act_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);

endmodule 
