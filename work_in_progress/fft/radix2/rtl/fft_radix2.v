`default_nettype none

module fft_radix2 #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POIN = 15,
    parameter TWIDDLE_WIDTH = 18,
    parameter TWIDDLE_POINT = 16,
    parameter DFT_SIZE = 3  //2**?
) (
    input wire clk,
    input wire din_valid,
    input wire [(2**DFT_SIZE)*DIN_WIDTH-1:0] din_re, din_im,

    output wire [2**(DFT_SIZE)*(DIN_WIDTH+DFT_SIZE)-1:0] dout_re, dout_im,
    output wire dout_valid
);

wire [DFT_SIZE:0] butterfly [2**(DFT_SIZE)*(DIN_WIDTH+DFT_SIZE)-1:0];

localparam ITERS = DFT_SIZE+1;
genvar i


endmodule
