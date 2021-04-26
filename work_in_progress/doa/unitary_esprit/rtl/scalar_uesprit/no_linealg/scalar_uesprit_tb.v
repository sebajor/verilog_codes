`default_nettype none
`include "scalar_uesprit.v"

module scalar_uesprit_tb #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    parameter ACC_WIDTH = 20,
    parameter ACC_POINT = 16,
    parameter DOUT_WIDTH = 32
) (
    input wire clk,
    input wire new_acc,

    input wire [DIN_WIDTH-1:0] din1_re, din1_im,
    input wire [DIN_WIDTH-1:0] din2_re, din2_im,
    input wire din_valid,
    
    output wire [DOUT_WIDTH-1:0] r11, r22, r12_re, r12_im,
    output wire dout_valid
);



scalar_uesprit #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .ACC_WIDTH(ACC_WIDTH),
    .ACC_POINT(ACC_POINT),
    .DOUT_WIDTH(DOUT_WIDTH)
) scalar_uesprit_tb (
    .clk(clk),
    .new_acc(new_acc),
    .din1_re(din1_re),
    .din1_im(din1_im),
    .din2_re(din2_re),
    .din2_im(din2_im),
    .din_valid(din_valid),
    .r11(r11),
    .r22(r22),
    .r12_re(r12_re),
    .r12_im(r12_im),
    .dout_valid(dout_valid)
);

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end

endmodule
