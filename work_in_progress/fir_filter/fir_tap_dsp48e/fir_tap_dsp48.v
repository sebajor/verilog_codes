`default_nettype none

/*
pre_add1 width (A): 30  
pre_add2 width (D): 25
mult_in  width (B): 18
post_add width (C): 48

**the post add signal could work
*/

module fir_tap_dsp48 #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    parameter COEF_WIDTH = 16,
    parameter COEF_POINT = 14,
    parameter POST_ADD = 48
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] pre_add1, pre_add2,
    input wire signed [COEF_WIDTH-1:0] coeff,
    input wire signed [POST_ADD-1:0] post_add,
    input wire din_valid,
    
    output wire signed [POST_ADD-1:0] dout,
    output wire dout_valid
);
   
reg signed [COEF_WIDTH-1:0] mult_delay=0;
reg signed [DIN_WIDTH:0] pre_add=0;
reg din_valid_r=0;
reg signed [POST_ADD-1:0] post_add_r=0;

always@(posedge clk)begin
    mult_delay <= coeff;
    pre_add <= $signed(pre_add1)+$signed(pre_add2);
    din_valid_r <= din_valid;
    post_add_r <= post_add;
end

reg signed [POST_ADD-2:0] mult_out=0;
reg signed [POST_ADD-1:0] post_add_rr=0;
reg din_valid_rr=0;
always@(posedge clk)begin
    din_valid_rr <= din_valid_r;
    mult_out <= $signed(pre_add)*$signed(mult_delay);
    post_add_rr <= post_add_r;
end

reg signed [POST_ADD-1:0] dout_r=0;
reg dout_valid_r=0;
always@(posedge clk)begin
    dout_r <= $signed(mult_out)+$signed(post_add_rr);
    dout_valid_r <= din_valid_rr;
end

assign dout = dout_r;
assign dout_valid = dout_valid_r;


endmodule
