`default_nettype none

module dss_calibrator #(
    parameter DIN_WIDHT = 18,
    parameter DIN_POINT = 17,
    parameter PARALLEL = 8,
    parameter FFT_SIZE = 1024,
    parameter ACC_WIDTH = 64,
    parameter ACC_POINT = 34,
    parameter DOUT_WIDTH = 64
)(
    input wire clk,
    input wire signed [DIN_WIDHT*PARALLEL-1:0] din_re, din_im,
    input wire sync_in
);

wire signed [DOUT_WIDTH-1:0] r12_re, r12_im;
wire [DOUT_WIDTH-1:0] r11, r22;
wire corr_valid;

correlator #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .VECTOR_LEN(VECTOR_LEN),
    .ACC_WIDTH(ACC_WIDTH),
    .ACC_POINT(ACC_POINT),
    .DOUT_WIDTH(DOUT_WIDTH)
) correlator_inst (
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
    .dout_valid(corr_valid)
);



endmodule
