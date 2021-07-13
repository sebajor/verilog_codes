`default_nettype none
`include "autoscale.v"

module autoscale_tb #(
    parameter MAX_SHIFT = 10,
    parameter DIN_WIDTH = 32
) (
    input wire clk,
    input wire [DIN_WIDTH-1:0] din1, din2,
    input wire din_valid,
    output wire [DIN_WIDTH-1:0] dout1, dout2,
    output wire dout_valid,
    output wire [$clog2(DIN_WIDTH)-1:0] shift_value
);



autoscale #(
    .MAX_SHIFT(MAX_SHIFT),
    .DIN_WIDTH(DIN_WIDTH)
) autoscale_inst (
    .clk(clk),
    .din1(din1),
    .din2(din2),
    .din_valid(din_valid),
    .dout1(dout1),
    .dout2(dout2),
    .dout_valid(dout_valid),
    .shift_value(shift_value)
);

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end



endmodule 
