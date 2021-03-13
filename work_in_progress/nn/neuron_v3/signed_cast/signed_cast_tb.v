`default_nettype none 
`include "signed_cast.v"

module signed_cast_tb #(
    parameter PARALLEL = 8,
    parameter DIN_WIDTH = 8,
    parameter DIN_INT = 4,
    parameter DOUT_WIDTH = 16,
    parameter DOUT_INT = 3
) (
    input wire clk,
    input wire [DIN_WIDTH*PARALLEL-1:0] din,
    input wire din_valid,
    output wire [DOUT_WIDTH*PARALLEL-1:0] dout,
    output wire dout_valid
);

signed_cast #(
    .PARALLEL(PARALLEL),
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_INT(DIN_INT),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_INT(DOUT_INT)
) signed_cast_inst (
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
