`default_nettype none
`include "moving_average_unsign.v"
`include "dsp48_mult.v"


module avg_pow #(
    parameter DIN_WIDTH = 8,
    parameter DELAY_LINE = 32
)(
    input wire clk,
    input wire rst,

    input wire signed [DIN_WIDTH-1:0] din,
    input wire din_valid,

    output wire [2*DIN_WIDTH-1:0] dout,
    output wire dout_valid
);



wire [2*DIN_WIDTH-1:0] din_pow;
wire din_pow_valid;

dsp48_mult #(
    .DIN1_WIDTH(DIN_WIDTH),
    .DIN2_WIDTH(DIN_WIDTH),
    .DOUT_WIDTH(2*DIN_WIDTH)
) pow_mult (
    .clk(clk),
    .rst(1'b0),
    .din1(din),
    .din2(din),
    .din_valid(din_valid),
    .dout(din_pow),
    .dout_valid(din_pow_valid)
);

//moving average
moving_average_unsign #(
    .DIN_WIDTH(2*DIN_WIDTH),
    .DIN_POINT(2*DIN_WIDTH-2),
    .WINDOW_LEN(DELAY_LINE),
    .DOUT_WIDTH(2*DIN_WIDTH),
    .APPROX("nearest")   //truncate, nearest
) mov_avg(
    .clk(clk),
    .rst(1'b0),
    .din(din_pow),
    .din_valid(din_pow_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);


endmodule
