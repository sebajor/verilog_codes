`default_nettype none
`include "quad_root.v"

module quad_root_tb #(
    parameter DIN_WIDTH = 16,
    parameter SQRT_IN_WIDTH = 10,
    parameter SQRT_IN_PT = 7,
    parameter SQRT_OUT_WIDTH = 16,
    parameter SQRT_OUT_PT = 13
) (
    input wire clk, 
    input wire signed [DIN_WIDTH-1:0] b, c,
    input wire din_valid,

    output wire signed [SQRT_OUT_WIDTH-1:0] x1,x2,
    output wire dout_valid
);


quad_root #(
    .DIN_WIDTH(DIN_WIDTH),
    .SQRT_IN_WIDTH(SQRT_IN_WIDTH),
    .SQRT_OUT_WIDTH(SQRT_OUT_WIDTH),
    .SQRT_OUT_PT(SQRT_OUT_PT) 
) quad_root_inst (
    .clk(clk), 
    .b(b),
    .c(c),
    .din_valid(din_valid),
    .x1(x1),
    .x2(x2),
    .dout_valid(dout_valid)
);

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end
endmodule
