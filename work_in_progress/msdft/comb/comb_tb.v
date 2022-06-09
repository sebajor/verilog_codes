`default_nettype none
`include "includes.v"
`include "comb.v"

module comb_tb #(
    parameter DIN_WIDTH = 16,
    parameter DELAY_LINE = 16,
    parameter DOUT_WIDHT = 17
) (
    input wire clk,
    input wire rst,
    input wire signed [DIN_WIDTH-1:0] din,
    input wire din_valid,
    input wire [31:0] delay_line,
    output wire signed [DOUT_WIDHT-1:0] dout,
    output wire dout_valid
);



comb #(
    .DIN_WIDTH(DIN_WIDTH),
    .DELAY_LINE(DELAY_LINE),
    .DOUT_WIDHT(DOUT_WIDHT)
) comb_inst (
    .clk(clk),
    .rst(rst),
    .din(din),
    .din_valid(din_valid),
    .delay_line(delay_line),
    .dout(dout),
    .dout_valid(dout_valid)
);

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end


endmodule
