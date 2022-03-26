`default_nettype none
`include "correlator.v"
`include "correlation_mults.v"
`include "includes.v"

module correlator_tb #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    parameter VECTOR_LEN = 64,
    parameter ACC_WIDTH = 20,   //cast after the corr mults 
    parameter ACC_POINT = 16,
    parameter DOUT_WIDTH = 32 
) (
    input wire clk,
    input wire new_acc, //this signal comes before the first value of the frame

    input wire signed [DIN_WIDTH-1:0] din1_re, din1_im,
    input wire signed [DIN_WIDTH-1:0] din2_re, din2_im,
    input wire din_valid,

    output wire [DOUT_WIDTH-1:0] r11, r22, r12_re, r12_im,
    output wire dout_valid
);

correlator #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .VECTOR_LEN(VECTOR_LEN),
    .ACC_WIDTH(ACC_WIDTH),
    .ACC_POINT(ACC_POINT),
    .DOUT_WIDTH(DOUT_WIDTH)
) correlator_inst (
    .clk(clk),
    .new_acc(new_acc),
    .din1_re(din1_re),
    .din1_im(din1_im),
    .din2_re(din2_re),
    .din2_im(din2_im),
    .din_valid(din_valid),
    .r11(r11),
    .r22(r22),
    .r12_re(r12_re),
    .r12_im(r12_im),
    .dout_valid(dout_valid)
);

reg [31:0] counter=0;
always@(posedge clk)begin
    if(new_acc)
        counter <=0;
    else
        counter <= counter+1;
end


endmodule
