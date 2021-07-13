`default_nettype none
//`include "dsp48_mult.v"

module complex_power #(
    parameter DIN_WIDTH = 16
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din_re, din_im,
    input wire din_valid,
    output wire [2*DIN_WIDTH:0] dout,
    output wire dout_valid
);

//re pow
wire [2*DIN_WIDTH-1:0] re_pow;
wire pow_valid;

dsp48_mult #(
    .DIN1_WIDTH(DIN_WIDTH),
    .DIN2_WIDTH(DIN_WIDTH),
    .DOUT_WIDTH(2*DIN_WIDTH)
)re_pow_mult (
    .clk(clk),
    .rst(1'b0),
    .din1(din_re),
    .din2(din_re),
    .din_valid(din_valid),
    .dout(re_pow),
    .dout_valid(pow_valid)
);

//im pow
wire [2*DIN_WIDTH-1:0] im_pow;

dsp48_mult #(
    .DIN1_WIDTH(DIN_WIDTH),
    .DIN2_WIDTH(DIN_WIDTH),
    .DOUT_WIDTH(2*DIN_WIDTH)
) im_pow_mult (
    .clk(clk),
    .rst(1'b0),
    .din1(din_im),
    .din2(din_im),
    .din_valid(din_valid),
    .dout(im_pow),
    .dout_valid()
);

//add them
reg [2*DIN_WIDTH:0] out=0;
reg dout_valid_r=0;
always@(posedge clk)begin
    out <= im_pow+re_pow;
    dout_valid_r <= pow_valid; 
end

assign dout_valid = dout_valid_r;
assign dout = out;

endmodule
