`default_nettype none
//`include "includes.v"
//`include "r22sdf_fft_stage.v"

module r22sdf_fft_stage_tb #(
    parameter STAGE_NUMBER =2,
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    parameter TWIDDLE_WIDTH = 16,
    parameter TWIDDLE_POINT = 14,
    parameter TWIDDLE_FILE = "twiddles/stage64_16_14",
    parameter DELAY_BUTTERFLIES = 0,
    parameter DELAY_TYPE = "DELAY"    //delay for the feedback
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din_re, din_im,
    input wire din_valid,
    input wire rst, 

    output wire signed [DIN_WIDTH+1:0] dout_re, dout_im,
    output wire dout_valid
);

initial begin
    $display("%s", TWIDDLE_FILE);
end

r22sdf_fft_stage #(
    .STAGE_NUMBER(STAGE_NUMBER),
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .TWIDDLE_WIDTH(TWIDDLE_WIDTH),
    .TWIDDLE_POINT(TWIDDLE_POINT),
    .TWIDDLE_FILE(TWIDDLE_FILE),
    .DELAY_BUTTERFLIES(DELAY_BUTTERFLIES),
    .DELAY_TYPE(DELAY_TYPE)
) r22sdf_fft_stage_inst (
    .clk(clk),
    .din_re(din_re), 
    .din_im(din_im),
    .din_valid(din_valid),
    .rst(rst), 
    .dout_re(dout_re),
    .dout_im(dout_im),
    .dout_valid(dout_valid)
);

endmodule
