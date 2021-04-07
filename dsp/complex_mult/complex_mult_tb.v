
`default_nettype none 
`include "complex_mult.v"

module complex_mult_tb #(
    parameter DIN1_WIDTH = 16,
    parameter DIN2_WIDTH = 16
) (
    input wire clk,
    
    input wire [DIN1_WIDTH-1:0] din1_re, din1_im,
    input wire [DIN2_WIDTH-1:0] din2_re, din2_im,

    input wire din_valid,

    output wire [DIN1_WIDTH+DIN2_WIDTH:0] dout_re,
    output wire [DIN1_WIDTH+DIN2_WIDTH:0] dout_im,

    output wire dout_valid
);

complex_mult #(
    .DIN1_WIDTH(DIN1_WIDTH),
    .DIN2_WIDTH(DIN2_WIDTH)
) complex_mult_inst (
    .clk(clk),
    .din1_re(din1_re),
    .din1_im(din1_im),
    .din2_re(din2_re),
    .din2_im(din2_im),
    .din_valid(din_valid),
    .dout_re(dout_re),
    .dout_im(dout_im),
    .dout_valid(dout_valid)
);



initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end

endmodule
