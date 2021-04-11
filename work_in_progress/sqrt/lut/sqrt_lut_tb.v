`default_nettype none
`include "sqrt_lut.v"

module sqrt_lut_tb #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 10,
    parameter DOUT_WIDTH = 16,
    parameter DOUT_POINT = 12,
    parameter SQRT_FILE = "sqrt.hex"
) (
    input wire clk,
    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,

    output wire [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);


sqrt_lut #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT),
    .SQRT_FILE(SQRT_FILE)
) sqrt_lut_inst (
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
