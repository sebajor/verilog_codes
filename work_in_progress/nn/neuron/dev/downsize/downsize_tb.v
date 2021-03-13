`default_nettype none
`include "downsize.v"

module downsize_tb #(
    parameter PARALLEL_IN = 4,
    parameter DIN_WIDTH = 32,
    parameter DOUT_WIDTH = 16
) (
    input clk,
    input [PARALLEL_IN*DIN_WIDTH-1:0] din,
    output [PARALLEL_IN*DOUT_WIDTH-1:0] dout
);

downsize #(
    .PARALLEL_IN(PARALLEL_IN),
    .DIN_WIDTH(DIN_WIDTH),
    .DOUT_WIDTH(DOUT_WIDTH) 
) donwsize_inst (
    .clk(clk),
    .din(din),
    .dout(dout)
);


initial begin
    $dumpfile("sim.vcd");
    $dumpvars();
end

endmodule
