`default_nettype none
`include "sqrt_fix.v"

module sqrt_fix_tb #(
    parameter DIN_WIDTH = 8,
    parameter DIN_POINT = 6
) (
    input wire clk,
    output wire busy,
    input wire din_valid,
    input wire [DIN_WIDTH-1:0] din,
    output wire [DIN_WIDTH-1:0] dout,
    output wire [DIN_WIDTH-1:0] reminder,
    output wire dout_valid
);


sqrt_fix #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT)
) sqrt_fix_inst (
    .clk(clk),
    .busy(busy),
    .din_valid(din_valid),
    .din(din),
    .dout(dout),
    .reminder(reminder),
    .dout_valid(dout_valid)
);
initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end
endmodule
