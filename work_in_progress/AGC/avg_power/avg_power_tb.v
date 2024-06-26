`default_nettype none
`include "avg_power.v"
`include "includes.v"

module avg_power_tb #(
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

avg_power #(
    .DIN_WIDTH(),
    .DELAY_LINE()
) avg_power_inst (
    .clk(clk),
    .rst(rst),
    .din(din),
    .din_valid(din_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);

endmodule
