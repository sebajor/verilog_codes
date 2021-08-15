`default_nettype none
`include "includes.v"

module biquad #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    parameter COEF_WIDTH = 16,
    parameter COEF_POINT = 14,
    parameter ACC1_WIDTH = 32,
    parameter ACC1_POINT = 14,
    parameter ACC2_WIDTH = 32,
    parameter ACC2_POINT = 14
) (
    input wire clk, 
    input wire rst,

    input wire signed [DIN_WIDTH-1:0] din,
    input wire din_valid,
    input wire signed [COEF_WIDTH-1:0] b0, b1,b2,a0,a1,

    output wire signed [ACC2_WIDTH-1:0] dout,
    output wire dout_valid
);

reg signed [DIN_WIDTH-1:0] din_dly=0, din_dly2=0;
always@(posedge clk)begin
    din_dly <= din;
    din_dly2<= din;
end

//the mults add 3 delay
localparam MUL1_POINT = DIN_POINT+COEF_POINT;
wire signed [DIN_WIDTH+COEF_WIDTH-1:0] b0_mul, b1_mul, b2_mul;
wire b0_mul_valid;
dsp48_mult #(
    .DIN1_WIDTH(DIN_WIDTH), 
    .DIN2_WIDTH(COEF_WIDTH),
    .DOUT_WIDTH(DIN_WIDTH+COEF_WIDTH)
) b0_mult (
    .clk(clk),
    .rst(rst),
    .din1(din),
    .din2(b0),
    .din_valid(din_valid),
    .dout(b0_mul),
    .dout_valid(b0_mul_valid)
);


dsp48_mult #(
    .DIN1_WIDTH(DIN_WIDTH), 
    .DIN2_WIDTH(COEF_WIDTH),
    .DOUT_WIDTH(DIN_WIDTH+COEF_WIDTH)
) b1_mult (
    .clk(clk),
    .rst(rst),
    .din1(din_dly),
    .din2(b1),
    .din_valid(din_valid),
    .dout(b1_mul),
    .dout_valid()
);

dsp48_mult #(
    .DIN1_WIDTH(DIN_WIDTH), 
    .DIN2_WIDTH(COEF_WIDTH),
    .DOUT_WIDTH(DIN_WIDTH+COEF_WIDTH)
) b2_mult (
    .clk(clk),
    .rst(rst),
    .din1(din_dly2),
    .din2(b2),
    .din_valid(din_valid),
    .dout(b2_mul),
    .dout_valid()
);

//cast data into the ACC1 format
wire signed [ACC1_WIDTH-1:0] b0mul_cast, b1mul_cast, b2mul_cast;
wire b0mul_cast_valid;
signed_cast #(
    .DIN_WIDTH(DIN_WIDTH+COEF_WIDTH),
    .DIN_POINT(MUL1_POINT),
    .DOUT_WIDTH(ACC1_WIDTH),
    .DOUT_POINT(ACC1_POINT)
) mul0_cast(
    .clk(clk), 
    .din(b0_mul),
    .din_valid(b0_mul_valid),
    .dout(b0mul_cast),
    .dout_valid(b0mul_cast_valid)
);

signed_cast #(
    .DIN_WIDTH(DIN_WIDTH+COEF_WIDTH),
    .DIN_POINT(MUL1_POINT),
    .DOUT_WIDTH(ACC1_WIDTH),
    .DOUT_POINT(ACC1_POINT)
) mul1_cast(
    .clk(clk), 
    .din(b1_mul),
    .din_valid(b0_mul_valid),
    .dout(b1mul_cast),
    .dout_valid()
);
signed_cast #(
    .DIN_WIDTH(DIN_WIDTH+COEF_WIDTH),
    .DIN_POINT(MUL1_POINT),
    .DOUT_WIDTH(ACC1_WIDTH),
    .DOUT_POINT(ACC1_POINT)
) mul2_cast(
    .clk(clk), 
    .din(b2_mul),
    .din_valid(b0_mul_valid),
    .dout(b2mul_cast),
    .dout_valid()
);

//adders
reg signed [ACC1_WIDTH-1:0] sum_b2_b1=0, delay_b0, acc1=0;
reg acc1_valid=0, acc1_valid_pre=0;
always@(posedge clk)begin
    if(rst)begin
        acc1_valid <=0;
        sum_b2_b1 <=0;
        delay_b0<=0;
        acc1 <=0;
    end
    else if(b0mul_cast_valid)begin
        sum_b2_b1 <= $signed(b2mul_cast)+$signed(b1mul_cast);
        delay_b0 <= $signed(b0mul_cast);
        acc1_valid_pre <=0;
        acc1_valid <= acc1_valid_pre;
        acc1 <=$signed(delay_b0)+$signed(sum_b2_b1);
    end
end


endmodule
