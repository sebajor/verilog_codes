`default_nettype none
`include "../../stable/macc/macc.v"

module neuron #(
    parameter PARALLEL_IN = 4,
    parameter DIN_WIDTH = 8,
    parameter DIN_INT = 2,
    parameter WEIGHT_WIDTH = 16,
    parameter WEIGHT_INT = 2,
    parameter WEIGHT_ADDR = 16, //numbers of addrs; the number of weights are
                                // W_ADDR*PARALLEL_IN
    parameter ACC_WIDTH = 20,   //accumulator input width
    parameter ACT_WIDTH = 10,   //activation function input width
    parameter ACT_INT = 4,      //activation function input int
    parameter DOUT_WIDTH = 16,
    parameter DOUT_INT = 2,
    parameter WEIGHT_FILE = "weight_test.mem",
    parameter ACTIVATION = "sigmoid",
    parameter ACT_ROM_FILE = "sigmoid_hex.mem"
) (
    input clk,
    input rst,
    input [DIN_WIDTH*PARALLEL_IN-1:0] din,
    input din_valid,
    input last,
    output [DOUT_WIDTH-1:0] dout,
    output dout_valid
);


wire [PARALLEL_IN*WEIGHT_WIDTH-1:0] weight;
wire weight_valid;

mem_control #(
    .ADDR(WEIGHT_ADDR), 
    .DOUT_WIDTH(PARALLEL_IN*WEIGHT_WIDTH), 
    .WEIGHT_FILE(WEIGHT_FILE) 
) mem_ctrl_inst (
    .clk(clk),
    .rst(rst),
    .valid(valid),
    .dout(weight),
    .dout_valid(weight_valid)
);


//delay to sinc the din with weight
reg [DIN_WIDTH*PARALLEL_IN-1:0] din_r=0, din_rr=0;
reg din_val_r=0, din_val_rr =0;
reg last_r=0, last_rr=0;
always@(posedge clk)begin
    din_r <= din; din_rr <= din_r;
    if(rst)begin
        last_r <= 0; last_rr <= 0;
        din_val_r <= 0; din_val_rr <= 0;
    end
    else begin
        last_r <= last; last_rr <= last_r;
        din_val_r<= din_valid; din_val_rr <= din_val_r;
    end
end


wire [ACT_WIDTH-1:0] act_din;
wire act_en;


macc #(
    .PARALLEL_IN(PARALLEL_IN),
    .DATA1_WIDTH(DIN_WIDTH),
    .DATA1_INT(DIN_INT),
    .DATA2_WIDTH(WEIGHT_WIDTH),
    .DATA2_INT(WEIGHT_INT),
    .ACC_WIDTH(ACC_WIDTH),
    .DOUT_WIDTH(ACT_WIDTH),
    .DOUT_INT(ACT_INT)
) macc inst (
    .clk(clk),
    .din1(din_rr),
    .din2(weight),
    .en(din_val_rr),
    .rst(rst),
    .last(last_rr),
    .dout(act_din),
    .dout_valid(act_en)
);


//activation function instantiation
generate 
if(ACTIVATION=="sigmoid")begin
    sigmoid #(
        .OUT_WIDTH(DOUT_WIDTH),
        .OUT_INT(DOUT_INT),
        .IN_WIDTH(ACT_WIDTH),
        .IN_INT(ACT_INT),
        .FILENAME(ACT_ROM_FILE)
) sigmoid_inst (
    .clk(clk),
    .din(act_din),
    .din_valid(act_en),
    .dout(dout),
    .dout_valid(dout_valid)
);
end

else if(ACTIVATION=="relu") begin
relu #(
    .IN_WIDTH(ACT_WIDTH), 
    .IN_INT(ACT_INT),
    .OUT_WIDTH(DOUT_WIDTH),
    .OUT_INT(DOUT_INT)
) relu_inst (
    .clk(clk),
    .din(act_din),
    .din_valid(act_en),
    .dout(dout),
    .dout_valid(dout_valid)
);
end

else begin
    //default sigmoid
sigmoid #(
    .OUT_WIDTH(DOUT_WIDTH),
    .OUT_INT(DOUT_INT),
    .IN_WIDTH(ACT_WIDTH),
    .IN_INT(ACT_INT),
    .FILENAME(ACT_ROM_FILE)
) sigmoid_inst (
    .clk(clk),
    .din(act_din),
    .din_valid(act_en),
    .dout(dout),
    .dout_valid(dout_valid)
);


end

endgenerate


endmodule
