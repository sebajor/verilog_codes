`default_nettype none
`include "sigmoid.v"

module sigmoid_tb #(
    parameter DOUT_WIDTH = 8,
    parameter DUOT_INT = 1,
    parameter DIN_WIDTH = 16,
    parameter DIN_INT = 4,
    parameter FILENAME = "sigmoid_hex.mem"
) (
    input wire clk,
    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,
    output wire [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);

sigmoid #(
    .DOUT_WIDTH(DOUT_WIDTH),
    .DUOT_INT(DUOT_INT),
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_INT(DIN_INT),
    .FILENAME(FILENAME)
) sigmoid_inst (
    .clk(clk),
    .din(din),
    .din_valid(din_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end

endmodule
