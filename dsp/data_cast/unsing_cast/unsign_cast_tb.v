`default_nettype none
`include "unsign_cast.v"

module unsing_cast_tb #(
    parameter DIN_WIDTH = 8,
    parameter DIN_POINT = 4,
    parameter DOUT_WIDTH = 16, 
    parameter DOUT_POINT = 11
) (
    input wire clk, 
    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,
    output wire [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);

//increase int and frac
unsing_cast #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT)
) cast1 (
    .clk(clk), 
    .din(din),
    .din_valid(din_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);

//reduce int, incrase frac
unsing_cast #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .DOUT_WIDTH(),
    .DOUT_POINT()
) cast2 (
    .clk(clk), 
    .din(din),
    .din_valid(din_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);


unsing_cast #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .DOUT_WIDTH(),
    .DOUT_POINT()
) cast3 (
    .clk(clk), 
    .din(din),
    .din_valid(din_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);

unsing_cast #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .DOUT_WIDTH(),
    .DOUT_POINT()
) cast4 (
    .clk(clk), 
    .din(din),
    .din_valid(din_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);

endmodule
