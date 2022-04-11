`default_nettype none
`include "includes.v"
`include "arctan2.v"

module arctan2_tb #(
    parameter DIN_WIDTH = 16,
    parameter DOUT_WIDTH = 16,
    parameter ROM_FILE = "atan_rom.mem",
    parameter MAX_SHIFT = 7
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] y,x,
    input wire din_valid,

    output wire sys_ready,
    output wire signed [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);




arctan2 #(
    .DIN_WIDTH(DIN_WIDTH),
    .DOUT_WIDTH(DOUT_WIDTH),
    .ROM_FILE(ROM_FILE),
    .MAX_SHIFT(MAX_SHIFT)
) arctan2_inst (
    .clk(clk),
    .y(y),
    .x(x),
    .din_valid(din_valid),
    .sys_ready(sys_ready),
    .dout(dout),
    .dout_valid(dout_valid)
);

endmodule
