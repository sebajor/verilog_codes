`default_nettype none
`include "includes.v"

module rfi_detector #(
    parameter DIN_WIDTH = 18,
    //cast the inputs
    parameter IN_SHIFT = 6,
    parameter IN_WIDTH = 9,
    parameter IN_POINT = 8,
    parameter IN_DELAY = 0,
    //

    parameter DEBUG = 1

)(
    input wire clk,

    input wire signed [DIN_WIDTH-1:0] sig_re, sig_im,
    input wire signed [DIN_WIDTH-1:0] ref_re, ref_im,
    input wire din_valid,
    input wire sync_in,

    output wire dout_valid
);

wire signed [DIN_WIDTH-1:0] sig_re_shift, sig_im_shift, ref_re_shift, ref_im_shift;
wire [7:0] in_shift_warn;

shift #(
    .DATA_WIDTH(DIN_WIDTH),
    .DATA_TYPE("signed"),
    .SHIFT_VALUE(IN_SHIFT),
    .ASYNC(0),
    .OVERFLOW_WARNING(DEBUG)
) input_shift [3:0] (
    .clk(clk),
    .din({sig_re, sig_im, ref_re, ref_im}),
    .dout({sig_re_shift, sig_im_shift, ref_re_shift, ref_im_shift}),
    .warning(in_shift_warn)
);

reg sync_in_r=0, din_valid_r=0;
reg sync_cast=0;
always@(posedge clk)begin
    sync_in_r <= sync_in;
    sync_cast <= sync_in_r;
    din_valid_r <= din_valid;
end

wire signed [IN_WIDTH-1:0] sig_re_cast, sig_im_cast, ref_re_cast, ref_im_cast;
wire valid_cast;
wire [7:0] in_cast_warning;


signed_cast #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_WIDTH-1),
    .DOUT_WIDTH(IN_WIDTH),
    .DOUT_POINT(IN_POINT),
    .WARNING_OVERFLOW(DEBUG)
) input_casting [3:0] (
    .clk(clk), 
    .din({sig_re_shift, sig_im_shift, ref_re_shift, ref_im_shift}),
    .din_valid(din_valid_r),
    .dout({sig_re_cast, sig_im_cast, ref_re_cast, ref_im_cast}),
    .dout_valid(valid_cast),
    .warning(in_cast_warning)
);

wire signed [IN_WIDTH-1:0] sig_re_data, sig_im_data, ref_re_data, ref_im_data;
wire valid_data, sync_data;

delay #(
    .DATA_WIDTH(4*IN_WIDTH+2),
    .DELAY_VALUE(IN_DELAY)
) input_delay (
    .clk(clk),
    .din({sig_re_cast, sig_im_cast, ref_re_cast, ref_im_cast, valid_cast, sync_cast}),
    .dout({sig_re_data, sig_im_data, ref_re_data,ref_im_data, valid_data, sync_data})
);

//now we start


endmodule
