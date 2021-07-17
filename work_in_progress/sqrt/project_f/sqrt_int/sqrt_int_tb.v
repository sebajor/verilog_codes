`default_nettype none
`include "sqrt_int.v"

module sqrt_int_tb #(
    parameter DIN_WIDTH = 8
) (
    input wire clk,
    output wire busy,
    input wire din_valid,
    input wire [DIN_WIDTH-1:0] din,
    output wire [DIN_WIDTH-1:0] dout,
    output wire [DIN_WIDTH-1:0] reminder,
    output wire dout_valid
);


sqrt_int #(
    .DIN_WIDTH(DIN_WIDTH)
) sqrt_int_inst (
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
