`default_nettype none

/*  25x18 two comp multiplier, could be 48 bit accumulator  

*/


module dsp48_macc #(
    parameter DIN1_WIDTH = 16,
    parameter DIN2_WIDTH = 16,
    parameter DOUT_WIDTH = 48
)(
    input wire clk,
    input wire new_acc,

    input wire signed [DIN1_WIDTH-1:0] din1,
    input wire signed [DIN2_WIDTH-1:0] din2,
    input wire din_valid,

    output wire signed [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);

reg signed [DIN1_WIDTH-1:0]  pre_mult1=0;
reg signed [DIN2_WIDTH-1:0]  pre_mult2=0;
reg din_valid_r=0, new_acc_r=0;
always@(posedge clk)begin
    din_valid_r <= din_valid;
    pre_mult1 <= din1;
    pre_mult2 <= din2;
    new_acc_r <= new_acc;
end

//mult 
parameter MULT_WIDTH = DIN1_WIDTH+DIN2_WIDTH;
reg signed [MULT_WIDTH-1:0] mult=0;
reg mult_valid=0, new_acc_rr=0;
always@(posedge clk)begin
    mult <= $signed(pre_mult1)*$signed(pre_mult2);
    mult_valid <= din_valid_r;
    new_acc_rr<= new_acc_r;
end

//accumulator
//saturate??
reg signed [DOUT_WIDTH-1:0] acc=0;
always@(posedge clk)begin
    if(mult_valid)begin
        if(new_acc_rr)
            acc <= $signed(mult);
        else
            acc <= $signed(acc)+$signed(mult);
    end
end

reg dout_valid_r=0;
always@(posedge clk)
    dout_valid_r <= new_acc_r & din_valid_r;

assign dout_valid = dout_valid_r;
assign dout = acc;




endmodule
