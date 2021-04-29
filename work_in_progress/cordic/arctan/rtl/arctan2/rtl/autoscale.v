`default_nettype none
//`include "priority_encoder.v"
//`include "first_one_finder.v"
/*
    Compare two signed inputs and determine the optimal shifting to 
   use in best way the DIN_WIDTH bits.
   Like in the arctang we manage to just use the first quadrant the 
   input are always unsigned :)
*/


module autoscale #(
    parameter MAX_SHIFT = 10,
    parameter DIN_WIDTH = 32
) (
    input wire clk,
    input wire [DIN_WIDTH-1:0] din1, din2,
    input wire din_valid,
    output wire [DIN_WIDTH-1:0] dout1, dout2,
    output wire dout_valid
);

reg [DIN_WIDTH-1:0] index=0, din1_r=0, din2_r=0;
reg din_valid_r=0;

always@(posedge clk)begin
    din1_r <= din1; din2_r <= din2;
    index <= din1 | din2;
    din_valid_r <= din_valid;
end

//now we nee to found the first appearence of a 1 in index
//priority encoder
wire [$clog2(DIN_WIDTH)-1:0] first_one;
/*
priority_encoder #(
    .DIN_WIDTH(DIN_WIDTH)
)priority_encoder_inst (
    .din(index),
    .dout(first_one)
);
*/

first_one_finder #(
    .DIN_WIDTH(DIN_WIDTH)
)first_one_finder_inst (
    .clk(clk),
    .din(index),
    .din_valid(1'b1),
    .dout(first_one)
);
reg valid_r=0;
reg [DIN_WIDTH-1:0] din1_rr=0, din2_rr=0;
always@(posedge clk)begin
    din1_rr <= din1_r; din2_rr <= din2_r;
    valid_r <= din_valid_r;
end


//shift the data the rigth amount 
reg dout_valid_r=0;
reg [DIN_WIDTH-1:0] dout1_r=0, dout2_r=0;
wire [$clog2(DIN_WIDTH)-1:0] shift_val = DIN_WIDTH-2-first_one;
always@(posedge clk)begin
    dout_valid_r <= valid_r;
    if(shift_val>MAX_SHIFT)begin
        dout1_r <= din1_rr<<<(MAX_SHIFT);
        dout2_r <= din2_rr<<<(MAX_SHIFT);
    end
    else begin
        dout1_r <= din1_rr<<<(shift_val);
        dout2_r <= din2_rr<<<(shift_val);
    end
end

assign dout1 = dout1_r;
assign dout2 = dout2_r;
assign dout_valid = dout_valid_r;


endmodule
