`default_nettype none
`include "sigmoid.v"

module sigmoid_tb #(
    parameter OUT_WIDTH = 16,
    parameter OUT_INT = 1,
    parameter IN_WIDTH = 8,
    parameter IN_INT = 4,
    parameter FILENAME="sigmoid_hex.mem"
) (
    input clk,
    input [IN_WIDTH-1:0] din,
    input din_valid,
    output [OUT_WIDTH-1:0] dout,
    output dout_valid
);


sigmoid #(
    .OUT_WIDTH(OUT_WIDTH), 
    .OUT_INT(OUT_INT),
    .IN_WIDTH(IN_WIDTH), 
    .IN_INT(IN_INT),
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
