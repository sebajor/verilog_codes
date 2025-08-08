`default_nettype none

/*
*   author: sebastian jorquera
*   Note that for the stage=2 the delay type must be DELAY
*
*/
module r22sdf_fft_stage #(
    parameter STAGE_NUMBER =8,
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    parameter TWIDDLE_WIDTH = 16,
    parameter TWIDDLE_POINT = 14,
    parameter TWIDDLE_FILE = "twiddles/stage16_16_14",
    parameter DELAY_BUTTERFLIES = 0,
    parameter DELAY_TYPE = "RAM"    //delay for the feedback
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din_re, din_im,
    input wire din_valid,
    input wire rst, 

    output wire signed [DIN_WIDTH+1:0] dout_re, dout_im,
    output wire dout_valid
);


wire signed [DIN_WIDTH:0] bf1_dout_re, bf1_dout_im;
wire bf1_dout_valid;

r22sdf_bf1 #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .BUFFER_SIZE(STAGE_NUMBER),
    .DELAY_TYPE(DELAY_TYPE)
) r22sdf_bf1_inst  (
    .clk(clk), 
    .din_re(din_re),
    .din_im(din_im),
    .din_valid(din_valid),
    .rst(rst),
    .dout_re(bf1_dout_re),
    .dout_im(bf1_dout_im),
    .dout_valid(bf1_dout_valid)
);

wire signed [DIN_WIDTH:0] bf1_dout_re_r, bf1_dout_im_r;
wire bf1_dout_valid_r;

delay #(
    .DATA_WIDTH(2*DIN_WIDTH+3),
    .DELAY_VALUE(DELAY_BUTTERFLIES)
) delay_inst1 (
    .clk(clk),
    .din({bf1_dout_re, bf1_dout_im, bf1_dout_valid}),
    .dout({bf1_dout_re_r, bf1_dout_im_r, bf1_dout_valid_r})
);

wire signed [DIN_WIDTH+1:0] bf2_dout_re, bf2_dout_im;
wire bf2_dout_valid;

r22sdf_bf2 #(
    .DIN_WIDTH(DIN_WIDTH+1),
    .DIN_POINT(DIN_POINT),
    .BUFFER_SIZE(STAGE_NUMBER/2),
    .DELAY_TYPE(DELAY_TYPE)
) r22sdf_bf2_inst (
    .clk(clk), 
    .din_re(bf1_dout_re_r),
    .din_im(bf1_dout_im_r),
    .din_valid(bf1_dout_valid_r),
    .rst(rst),
    .dout_re(bf2_dout_re),
    .dout_im(bf2_dout_im),
    .dout_valid(bf2_dout_valid)
);


wire signed [DIN_WIDTH+1:0] bf2_dout_re_r, bf2_dout_im_r;
wire bf2_dout_valid_r;

delay #(
    .DATA_WIDTH(2*DIN_WIDTH+5),
    .DELAY_VALUE(DELAY_BUTTERFLIES)
) delay_inst2 (
    .clk(clk),
    .din({bf2_dout_re, bf2_dout_im, bf2_dout_valid}),
    .dout({bf2_dout_re_r, bf2_dout_im_r, bf2_dout_valid_r})
);

generate 
    if(STAGE_NUMBER!=2) begin
    r22sdf_twiddle_mult #(
        .DIN_WIDTH(DIN_WIDTH+2),
        .DIN_POINT(DIN_POINT),
        .FFT_SIZE(STAGE_NUMBER*2),
        .TWIDDLE_WIDTH(TWIDDLE_WIDTH),
        .TWIDDLE_POINT(TWIDDLE_POINT),
        .TWIDDLE_FILE(TWIDDLE_FILE),
        .DEBUG(0)
    ) r22sdf_twiddle_mult_inst (
        .clk(clk),
        .din_re(bf2_dout_re_r),
        .din_im(bf2_dout_im_r), 
        .din_valid(bf2_dout_valid_r),
        .rst(rst),
        .dout_re(dout_re),
        .dout_im(dout_im),
        .dout_valid(dout_valid)
    );
    end
    else begin
        assign dout_re = bf2_dout_re_r;
        assign dout_im = bf2_dout_im_r;
        assign dout_valid = bf2_dout_valid_r;
    end
endgenerate 

endmodule
