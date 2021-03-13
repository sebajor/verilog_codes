`default_nettype none
`include "relu.v"

module relu_tb #(
    parameter DIN_WIDTH = 16,
    parameter DIN_INT = 3,
    parameter DOUT_WIDTH = 8,
    parameter DOUT_INT =4
) (
    input clk,
    input signed [DIN_WIDTH-1:0] din,
    input din_valid,
    output signed [DOUT_WIDTH-1:0] dout,
    output dout_valid
);

relu #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_INT(DIN_INT),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_INT(DOUT_INT)
)relu_inst (
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
