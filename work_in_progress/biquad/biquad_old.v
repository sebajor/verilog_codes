`default_nettype none
`include "includes.v"

//Direct form 1 biquad
//H(z) = (b0+b1z+b2z**2)/(a0+a1z+a2z**2)    #we take a0=1

module biaqud #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,

    parameter COEF_WIDTH = 16,
    parameter COEF_POINT = 14,
    
    parameter ACC1_WIDTH = 32,  //first acc width (zeros)
    parameter ACC1_POINT = 14,
    parameter ACC2_WIDTH = 32,  //second acc width (poles)
    parameter ACC2_POINT = 14,  
) (
    input wire clk,
    input wire rst,

    input wire signed [DIN_WIDTH-1:0] din,
    input wire din_valid,

    input wire signed [COEF_WIDTH-1:0] b0, b1, b2, a0, a1,

    output wire signed [ACC2_WIDTH-1:0] dout,
    output wire dout_valid
);

reg signed [DIN_WIDTH-1:0] din_dly=0, din_dly2=0;
always@(posedge clk)begin
    din_dly <= din;
    din_dly2<= din;
end

localparam MUL1_POINT = DIN_POINT+COEF_POINT;

wire signed [DIN_WIDTH+COEF_WIDTH-1:0] b0_mul, b1_mul, b2_mul;
wire b0_mul_valid;
dsp48_mult #(
    .DIN1_WIDTH(DIN_WIDTH), 
    .DIN2_WIDTH(COEF_WIDTH),
    .DOUT_WIDTH(DIN_WIDTH+COEF_WIDTH)
) b0_mult (
    .clk(clk),
    .rst(1'b0),
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
) b0_mult (
    .clk(clk),
    .rst(1'b0),
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
) b0_mult (
    .clk(clk),
    .rst(1'b0),
    .din1(din_dly2),
    .din2(b2),
    .din_valid(din_valid),
    .dout(b2_mul),
    .dout_valid()
);

//add the zeros mult
reg signed [DIN_WIDTH+COEF_WIDTH:0] add_b1=0, add_b0=0, b0_mul_dly=0;
reg b0_mul_val_dly =0, b0_mul_val_dly2 =0
always@(posedge clk)begin
    b0_mul_dly <= $signed(b0_mul);
    add_b1 <= $signed(b2_mul)+$signed(b1_mul);
    add_b0 <= $signed(add_b1)+$signed(b0_mul_dly);
    b0_mul_val_dly <= b0_mul_valid;
    b0_mul_val_dly2 <= b0_mul_dly;
end

//convert 
wire signed [ACC1_WIDTH-1:0] zeros;
wire zeros_valid;

signed_cast #(
    .DIN_WIDTH(DIN_WIDTH+COEF_WIDTH+1),
    .DIN_POINT(MUL1_POINT),
    .DOUT_WIDTH(ACC1_WIDTH),
    .DOUT_POINT(ACC1_POINT)
) zeros_convert (
    .clk(clk), 
    .din(add_b1),
    .din_valid(b0_mul_val_dly2),
    .dout(zeros),
    .dout_valid(zeros_valid)
);


//poles
reg signed [ACC2_WIDTH-1:0] pole=0, pole_dly=0, pole_dly2=0;


endmodule
