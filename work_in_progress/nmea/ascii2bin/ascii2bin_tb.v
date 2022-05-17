`default_nettype none
`include "ascii2bin.v"

module ascii2bin_tb #(
    parameter DIGITS = 3
) (
    input wire clk,
    input wire rst,

    input wire [7:0] ascii_in,
    input wire din_valid,

    output wire [$clog2(10**(DIGITS))-1:0] dout,
    output wire dout_valid
);

wire loopback;

ascii2bin #(
    .DIGITS(DIGITS)
) ascii2bin_inst (
    .clk(clk),
    .rst(loopback),
    .ascii_in(ascii_in),
    .din_valid(din_valid),
    .dout(dout),
    .dout_valid(loopback)
);

assign dout_valid = loopback;

endmodule
