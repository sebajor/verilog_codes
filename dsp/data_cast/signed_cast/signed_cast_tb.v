`default_nettype none
`include "signed_cast.v"

module signed_cast_tb #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 12,
    parameter DOUT_WIDTH = 8,
    parameter DOUT_POINT = 4
) (
    input wire clk, 
    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,
    output wire [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);


signed_cast #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT)
)signed_cast_inst (
    .clk(clk), 
    .din(din),
    .din_valid(din_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);


endmodule
