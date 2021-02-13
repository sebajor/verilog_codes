`default_nettype none
`ifndef _PARALLEL_MACC_
    `define _PARALLEL_MACC_
    `include "/home/seba/Workspace/verilog_codes/dev/nn/neuron_v3/include.v"
`endif


/*
parallel inputs macc, the idea is:

    parallel_mult -> adder_tree -> acc

*/

module parallel_macc #(
    parameter PARALLEL = 8,
    parameter DIN_WIDTH = 8,
    parameter DIN_INT = 1,
    parameter WEIGHT_ADDRS = 64,  
    parameter WEIGHT_WIDTH = 16,
    parameter WEIGHT_INT = 1,
    parameter SUM_IN_WIDTH = 16,
    parameter SUM_IN_INT = 2,
    parameter ACC_OUT_WIDTH = 32,
    parameter ACC_OUT_INT = 10
) (
    input wire clk,
    input wire rst,
    //input wire [$clog2(WEIGHT_ADDRS):0] weight_addr,

    input wire signed [PARALLEL*DIN_WIDTH-1:0] din,
    input wire signed [PARALLEL*WEIGHT_WIDTH-1:0] weight,
    input wire din_valid,
    
    output wire signed [ACC_OUT_WIDTH-1:0] dout,
    output wire dout_valid
);

localparam DIN_POINT = DIN_WIDTH-DIN_INT;
localparam WEIGHT_POINT = WEIGHT_WIDTH-WEIGHT_INT;
localparam MULT_WIDTH = DIN_WIDTH+WEIGHT_WIDTH+1;
localparam MULT_POINT = DIN_POINT+WEIGHT_POINT;
localparam MULT_INT = MULT_WIDTH-MULT_POINT;

wire signed [MULT_INT-1:0] align_din, align_w;

//parallel multiplier
//the values are set to make the mult in full scale and 
//quantize afte taking the SUM_IN parameter

wire signed [MULT_WIDTH*PARALLEL-1:0] mult_out;
wire [PARALLEL-1:0] mult_valid;

parallel_mult #(
    .PARALLEL(PARALLEL),
    .DIN1_WIDTH(DIN_WIDTH),
    .DIN2_WIDTH(WEIGHT_WIDTH),
    .DOUT_WIDTH(MULT_WIDTH)
) parallel_mult_inst (
    .clk(clk),
    .din1(din),
    .din2(weight),
    .din_valid(din_valid),
    .dout(mult_out),
    .dout_valid(mult_valid)
);

//requantization
localparam SUM_IN_POINT = SUM_IN_WIDTH-SUM_IN_INT;

wire [PARALLEL*SUM_IN_WIDTH-1:0] sum_in;
wire sum_in_valid;

signed_cast #(
    .PARALLEL(PARALLEL),
    .DIN_WIDTH(MULT_WIDTH),
    .DIN_INT(MULT_INT),
    .DOUT_WIDTH(SUM_IN_WIDTH),
    .DOUT_INT(SUM_IN_INT)
) mult_cast_inst (
    .clk(clk),
    .din(mult_out),
    .din_valid(mult_valid[0]),
    .dout(sum_in),
    .dout_valid(sum_in_valid)
);

//adder tree

wire signed [SUM_IN_WIDTH+$clog2(PARALLEL)-1:0] sum_out;
wire sum_out_valid;

adder_tree #(
    .DATA_WIDTH(SUM_IN_WIDTH),
    .PARALLEL(PARALLEL)
)adder_tree_inst (
    .clk(clk),
    .din(sum_in),
    .in_valid(sum_in_valid),
    .dout(sum_out),
    .out_valid(sum_out_valid)
);

//sum_out has the same fractional bits as sum_in


//counter to create the sof and eof signals
//to do simulate this part by itself in other place!
reg [$clog2(WEIGHT_ADDRS):0] weight_addr= WEIGHT_ADDRS-1;
reg [$clog2(WEIGHT_ADDRS):0] weight_r= WEIGHT_ADDRS-1;
//we need to add a delay to the data to increase the counter (CHECK!!)
reg acc_din_valid_r=0;
reg signed [SUM_IN_WIDTH+$clog2(PARALLEL)-1:0] acc_din_r=0;
wire acc_din_valid;
wire signed [SUM_IN_WIDTH+$clog2(PARALLEL)-1:0] acc_din;
assign acc_din_valid = acc_din_valid_r;
assign acc_din = acc_din_r;


wire acc_sof, acc_eof;

always@(posedge clk)begin
    weight_r <= weight_addr;
    acc_din_valid_r <= sum_out_valid;
    acc_din_r <= sum_out;
    if(rst)begin
        weight_addr <= WEIGHT_ADDRS-1;
    end
    else if(sum_out_valid)begin
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


localparam ACC_IN_INT = SUM_IN_WIDTH+$clog2(PARALLEL)-SUM_IN_POINT;

acc #(
    .DIN_WIDTH(SUM_IN_WIDTH+$clog2(PARALLEL)),
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
    .dout(dout),
    .dout_valid(dout_valid)
);

endmodule
