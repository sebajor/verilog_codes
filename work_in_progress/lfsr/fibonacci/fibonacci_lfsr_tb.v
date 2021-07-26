`default_nettype none
`include "fibonacci_lfsr.v"

module fibonacci_lfsr_tb #(
    parameter DATA_WIDTH = 5,
    parameter POLY = 8'b0000101
) (
    input wire clk,
    input wire en,
    input wire rst,
    input wire [DATA_WIDTH-1:0] seed,
    output wire [DATA_WIDTH-1:0] dout
);


fibonacci_lfsr #(
    .DATA_WIDTH(DATA_WIDTH),
    .POLY(POLY)
) lfsr_inst (
    .clk(clk),
    .en(en),
    .rst(rst),
    .seed(seed),
    .dout(dout)
);


initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end

endmodule
