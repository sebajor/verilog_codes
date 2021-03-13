`default_nettype none
`include "relu.v"

module relu_tb #(
    parameter IN_WIDTH = 32,
    parameter IN_INT = 8,
    parameter OUT_WIDTH = 16,
    parameter OUT_INT = 4
) (
    input clk,
    input signed [IN_WIDTH-1:0] din,
    input din_valid,
    output signed [OUT_WIDTH-1:0] dout,
    output dout_valid
);



relu #(
    .IN_WIDTH(IN_WIDTH),
    .IN_INT(IN_INT),
    .OUT_WIDTH(OUT_WIDTH),
    .OUT_INT(OUT_INT) 
) relu_inst (
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
