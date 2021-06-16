`default_nettype none
`include "uart_tx.v"

module uart_tx_tb #(
    parameter CLK_FREQ = 25_000_000,
    parameter BAUD_RATE = 115200
) (
    input wire [7:0] axis_tdata,
    input wire axis_tvalid,
    output wire axis_tready,
    input wire clk,
    output wire tx_data
);

uart_tx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
) uart_tx_inst (
    .axis_tdata(axis_tdata),
    .axis_tvalid(axis_tvalid),
    .axis_tready(axis_tready),
    .clk(clk),
    .tx_data(tx_data)
);


initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end

endmodule
