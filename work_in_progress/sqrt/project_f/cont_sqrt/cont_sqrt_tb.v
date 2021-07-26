`default_nettype none
`include "cont_sqrt.v"

module cont_sqrt_tb #(
    parameter DIN_WIDTH = 8,
    parameter DIN_POINT = 6
) (
    input wire clk, 
    input wire rst,
    input wire din_valid,
    input wire [DIN_WIDTH-1:0] din,
    output wire [DIN_WIDTH-1:0] dout,
    output wire dout_valid
);

cont_sqrt #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT)
) sqrt_inst (
    .clk(clk), 
    .rst(rst),
    .din_valid(din_valid),
    .din(din),
    .dout(dout),
    .dout_valid(dout_valid)
);

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end


endmodule
