`default_nettype none

module r22sdf_fft1024_tb (
    input wire clk,
    input wire rst,
    input wire din_valid,
    input wire signed [15:0] din_re, din_im,

    output wire signed [20:0] dout_re, dout_im,
    output wire dout_valid
    );



localparam FFT_SIZE = 1024;
localparam DIN_WIDTH = 16;
localparam DIN_POINT = 14;
r22sdf_fft1024 r22sdf_fft1024_inst (
    .clk(clk),
    .rst(rst),
    .din_valid(din_valid),
    .din_re(din_re),
    .din_im(din_im),
    .dout_re(dout_re),
    .dout_im(dout_im),
    .dout_valid(dout_valid)
    );

endmodule