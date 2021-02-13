`default_nettype none
`include "/home/seba/Workspace/verilog_codes/dev/nn/neuron_v3/single_perceptron/include.v"


/*
This perceptron just have one input (not multiple, like parallel pereptron)
the main difference is that we only utilize one multiplier and dont have
an adder tree previoud the accumulator
*/

module single_perceptron #(
    parameter DIN_WIDTH = 8,
    parameter DIN_INT = 1,
    parameter WEIGHT_WIDTH = 16,
    parameter WEIGHT_INT = 2,
    parameter WEIGHT_ADDRS = 512,
    parameter BIAS_WIDTH = 16,
    parameter BIAS_INT = 4,
    //accumulator 
    parameter ACC_IN_WIDTH = 16,
    parameter ACC_IN_INT = 3,
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

localparam DIN_POINT = DIN_WIDTH-DIN_INT;
localparam WEIGHT_POINT = WEIGHT_WIDTH-WEIGHT_INT;
localparam MULT_WIDTH = WEIGHT_WIDTH+DIN_WIDTH+1;
localparam MULT_POINT = DIN_POINT+WEIGHT_POINT;
localparam MULT_INT = MULT_WIDTH-MULT_POINT;

wire signed [MULT_WIDTH-1:0] mult_out;
wire mult_out_valid;

//this module is in parallel_mult.v
dsp48_mult #(
    .DIN1_WIDTH(DIN_WIDTH),
    .DIN2_WIDTH(WEIGHT_WIDTH),
    .DOUT_WIDTH(MULT_WIDTH)
) dsp48_mult_inst (
    .clk(clk),
    .din1(din),
    .din2(weight),
    .din_valid(din_valid),
    .dout(mult_out),
    .dout_valid(mult_out_valid)
);

wire signed [ACC_IN_WIDTH-1:0] acc_in;
wire acc_in_valid;

signed_cast #(
    .PARALLEL(1),
    .DIN_WIDTH(MULT_WIDTH),
    .DIN_INT(MULT_INT),
    .DOUT_WIDTH(ACC_IN_WIDTH),
    .DOUT_INT(ACC_IN_INT)
) mult_cast_inst (
    .clk(clk),
    .din(mult_out),
    .din_valid(mult_out_valid),
    .dout(acc_in),
    .dout_valid(acc_in_valid)
);


//counter to create the sof and eof signals
//to do simulate this part by itself in other place!
reg [$clog2(WEIGHT_ADDRS):0] weight_addr= WEIGHT_ADDRS-1;
reg [$clog2(WEIGHT_ADDRS):0] weight_r= WEIGHT_ADDRS-1;
//we need to add a delay to the data to increase the counter (CHECK!!)
reg acc_din_valid_r=0;
reg signed [ACC_IN_WIDTH-1:0] acc_din_r=0;
wire acc_din_valid;
wire signed [ACC_IN_WIDTH-1:0] acc_din;
assign acc_din_valid = acc_din_valid_r;
assign acc_din = acc_din_r;


wire acc_sof, acc_eof;

always@(posedge clk)begin
    weight_r <= weight_addr;
    acc_din_valid_r <= acc_in_valid;
    acc_din_r <= acc_in;
    if(rst)begin
        weight_addr <= WEIGHT_ADDRS-1;
    end
    else if(acc_in_valid)begin
        if(weight_addr==WEIGHT_ADDRS-1)
            weight_addr <= 0;
        else 
            weight_addr <= weight_addr+1;
    end
    else
        weight_addr <= weight_addr;
end

assign acc_sof = (weight_r==WEIGHT_ADDRS-1) & (weight_addr==0);
assign acc_eof = (weight_r==WEIGHT_ADDRS-2) & (weight_addr==WEIGHT_ADDRS-1);



wire signed [ACC_OUT_WIDTH-1:0] acc_out;
wire acc_out_valid;

//accumulator... create the eof and sof based into the parallel_macc
acc #(
    .DIN_WIDTH(ACC_IN_WIDTH),
    .DIN_INT(ACC_IN_INT),
    .DOUT_WIDTH(ACC_OUT_WIDTH),
    .DOUT_INT(ACC_OUT_INT)
) acc_inst (
    .clk(clk),
    .rst(rst),
    .din(acc_din),
    .din_valid(acc_din_valid),
    .din_sof(acc_sof),
    .din_eof(acc_eof),
    .dout(acc_out),
    .dout_valid(acc_out_valid)
);

//align bias
localparam BIAS_POINT= BIAS_WIDTH-BIAS_INT;
localparam ACC_OUT_POINT = ACC_OUT_WIDTH-ACC_OUT_INT;
wire signed [ACC_OUT_WIDTH-1:0] bias_align;
/*

//parece que esta extension esta fallando!
generate
    if(BIAS_POINT<ACC_OUT_POINT)
        assign bias_align = (bias <<<(ACC_OUT_POINT-BIAS_POINT));
    else
        assign bias_align = (bias >>>(BIAS_POINT-ACC_OUT_POINT));
endgenerate

*/

//casting with our module..
signed_cast #(
    .PARALLEL(1),
    .DIN_WIDTH(BIAS_WIDTH),
    .DIN_INT(BIAS_INT),
    .DOUT_WIDTH(ACC_OUT_WIDTH),
    .DOUT_INT(ACC_OUT_INT)
) bias_cast (
    .clk(clk),
    .din(bias),
    .din_valid(1'b1),
    .dout(bias_align),
    .dout_valid()
);

//add bias+accumulator output
reg signed [ACC_OUT_WIDTH:0] add_out_r=0;
reg add_out_valid_r=0;
wire signed [ACC_OUT_WIDTH:0] add_out;
wire add_out_valid;

assign add_out = add_out_r;
assign add_out_valid = add_out_valid_r;

always@(posedge clk)begin
    if(acc_out_valid)begin
        add_out_r <= $signed(bias_align)+$signed(acc_out);
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
