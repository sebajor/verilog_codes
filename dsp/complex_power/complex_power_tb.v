`default_nettype none
`include "complex_power.v"

module complex_power_tb #(
    parameter DIN_WIDTH = 16
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din_re, din_im,
    input wire din_valid,
    output wire [2*DIN_WIDTH:0] dout,
    output wire dout_valid
);

complex_power #(
    .DIN_WIDTH(DIN_WIDTH)
) complex_pow_inst (
    .clk(clk),
    .din_re(din_re), 
    .din_im(din_im),
    .din_valid(din_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end


endmodule
