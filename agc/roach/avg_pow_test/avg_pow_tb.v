`default_nettype none
`include "avg_pow.v"

module avg_pow_tb #(
    parameter DIN_WIDTH = 8,
    parameter PARALLEL = 8,
    parameter DELAY_LINE = 32
) (
    input wire clk,
    input wire rst,
    
    input wire [DIN_WIDTH*PARALLEL-1:0] din,
    input wire din_valid,

    output wire [2*DIN_WIDTH+$clog2(PARALLEL)-1:0] dout,
    output wire dout_valid
);



avg_pow #(
    .DIN_WIDTH(DIN_WIDTH),
    .PARALLEL(PARALLEL),
    .DELAY_LINE(DELAY_LINE)
) avg_pow_inst (
    .clk(clk),
    .rst(rst),
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
