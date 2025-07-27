`default_nettype none


module r22sdf_fft1024 (
    input wire clk,
    input wire rst,
    input wire din_valid,
    input wire signed [15:0] din_re, din_im,

    output wire signed [20:0] dout_re, dout_im,
    output wire dout_valid
    );

wire signed [15:0] din_re_stage512, din_im_stage512;
wire din_valid_stage512, dout_valid_stage512;
wire signed [17:0] dout_re_stage512, dout_im_stage512;


r22sdf_fft_stage #(
    .STAGE_NUMBER(512),
    .DIN_WIDTH(16),
    .DIN_POINT(14),
    .TWIDDLE_WIDTH(16),
    .TWIDDLE_POINT(14),
    .TWIDDLE_FILE("/home/seba/Workspace/verilog_codes/work_in_progress/r22sdf_spectrometer/twiddles/stage512_16_14"),
    .DELAY_BUTTERFLIES(0),
    .DELAY_TYPE("RAM")
) r22sdf_fft_stage_512 (
    .clk(clk),
    .din_re(din_re_stage512),
    .din_im(din_im_stage512),
    .din_valid(din_valid_stage512),
    .rst(rst),
    .dout_re(dout_re_stage512),
    .dout_im(dout_im_stage512),
    .dout_valid(dout_valid_stage512)
);

assign din_re_stage512 = din_re;
assign din_im_stage512 = din_im;
assign din_valid_stage512 = din_valid;

wire signed [17:0] dout_re_stage512_r, dout_im_stage512_r;
wire dout_valid_stage512_r;

delay #(
    .DATA_WIDTH(37),
    .DELAY_VALUE(0)
) delay_stage512 (
    .clk(clk),
    .din({dout_re_stage512, dout_im_stage512, dout_valid_stage512 }),
    .dout({dout_re_stage512_r, dout_im_stage512_r, dout_valid_stage512_r })
);

wire signed [17:0] din_re_stage128, din_im_stage128;
wire din_valid_stage128, dout_valid_stage128;
wire signed [19:0] dout_re_stage128, dout_im_stage128;


r22sdf_fft_stage #(
    .STAGE_NUMBER(128),
    .DIN_WIDTH(18),
    .DIN_POINT(14),
    .TWIDDLE_WIDTH(16),
    .TWIDDLE_POINT(14),
    .TWIDDLE_FILE("/home/seba/Workspace/verilog_codes/work_in_progress/r22sdf_spectrometer/twiddles/stage128_16_14"),
    .DELAY_BUTTERFLIES(0),
    .DELAY_TYPE("RAM")
) r22sdf_fft_stage_128 (
    .clk(clk),
    .din_re(din_re_stage128),
    .din_im(din_im_stage128),
    .din_valid(din_valid_stage128),
    .rst(rst),
    .dout_re(dout_re_stage128),
    .dout_im(dout_im_stage128),
    .dout_valid(dout_valid_stage128)
);

assign din_re_stage128 = dout_re_stage512_r;
assign din_im_stage128 = dout_im_stage512_r;
assign din_valid_stage128 = dout_valid_stage512_r;

wire signed [19:0] dout_re_stage128_r, dout_im_stage128_r;
wire dout_valid_stage128_r;

delay #(
    .DATA_WIDTH(41),
    .DELAY_VALUE(0)
) delay_stage128 (
    .clk(clk),
    .din({dout_re_stage128, dout_im_stage128, dout_valid_stage128 }),
    .dout({dout_re_stage128_r, dout_im_stage128_r, dout_valid_stage128_r })
);

wire signed [19:0] din_re_stage32, din_im_stage32;
wire din_valid_stage32, dout_valid_stage32;
wire signed [21:0] dout_re_stage32, dout_im_stage32;


r22sdf_fft_stage #(
    .STAGE_NUMBER(32),
    .DIN_WIDTH(20),
    .DIN_POINT(14),
    .TWIDDLE_WIDTH(16),
    .TWIDDLE_POINT(14),
    .TWIDDLE_FILE("/home/seba/Workspace/verilog_codes/work_in_progress/r22sdf_spectrometer/twiddles/stage32_16_14"),
    .DELAY_BUTTERFLIES(0),
    .DELAY_TYPE("RAM")
) r22sdf_fft_stage_32 (
    .clk(clk),
    .din_re(din_re_stage32),
    .din_im(din_im_stage32),
    .din_valid(din_valid_stage32),
    .rst(rst),
    .dout_re(dout_re_stage32),
    .dout_im(dout_im_stage32),
    .dout_valid(dout_valid_stage32)
);

assign din_re_stage32 = dout_re_stage128_r;
assign din_im_stage32 = dout_im_stage128_r;
assign din_valid_stage32 = dout_valid_stage128_r;

wire signed [21:0] dout_re_stage32_r, dout_im_stage32_r;
wire dout_valid_stage32_r;

delay #(
    .DATA_WIDTH(45),
    .DELAY_VALUE(0)
) delay_stage32 (
    .clk(clk),
    .din({dout_re_stage32, dout_im_stage32, dout_valid_stage32 }),
    .dout({dout_re_stage32_r, dout_im_stage32_r, dout_valid_stage32_r })
);

wire signed [21:0] din_re_stage8, din_im_stage8;
wire din_valid_stage8, dout_valid_stage8;
wire signed [23:0] dout_re_stage8, dout_im_stage8;


r22sdf_fft_stage #(
    .STAGE_NUMBER(8),
    .DIN_WIDTH(22),
    .DIN_POINT(14),
    .TWIDDLE_WIDTH(16),
    .TWIDDLE_POINT(14),
    .TWIDDLE_FILE("/home/seba/Workspace/verilog_codes/work_in_progress/r22sdf_spectrometer/twiddles/stage8_16_14"),
    .DELAY_BUTTERFLIES(0),
    .DELAY_TYPE("RAM")
) r22sdf_fft_stage_8 (
    .clk(clk),
    .din_re(din_re_stage8),
    .din_im(din_im_stage8),
    .din_valid(din_valid_stage8),
    .rst(rst),
    .dout_re(dout_re_stage8),
    .dout_im(dout_im_stage8),
    .dout_valid(dout_valid_stage8)
);

assign din_re_stage8 = dout_re_stage32_r;
assign din_im_stage8 = dout_im_stage32_r;
assign din_valid_stage8 = dout_valid_stage32_r;

wire signed [23:0] dout_re_stage8_r, dout_im_stage8_r;
wire dout_valid_stage8_r;

delay #(
    .DATA_WIDTH(49),
    .DELAY_VALUE(0)
) delay_stage8 (
    .clk(clk),
    .din({dout_re_stage8, dout_im_stage8, dout_valid_stage8 }),
    .dout({dout_re_stage8_r, dout_im_stage8_r, dout_valid_stage8_r })
);

wire signed [23:0] din_re_stage2, din_im_stage2;
wire din_valid_stage2, dout_valid_stage2;
wire signed [25:0] dout_re_stage2, dout_im_stage2;


r22sdf_fft_stage #(
    .STAGE_NUMBER(2),
    .DIN_WIDTH(24),
    .DIN_POINT(14),
    .TWIDDLE_WIDTH(16),
    .TWIDDLE_POINT(14),
    .TWIDDLE_FILE("/home/seba/Workspace/verilog_codes/work_in_progress/r22sdf_spectrometer/twiddles/stage2_16_14"),
    .DELAY_BUTTERFLIES(0),
    .DELAY_TYPE("DELAY")
) r22sdf_fft_stage_2 (
    .clk(clk),
    .din_re(din_re_stage2),
    .din_im(din_im_stage2),
    .din_valid(din_valid_stage2),
    .rst(rst),
    .dout_re(dout_re_stage2),
    .dout_im(dout_im_stage2),
    .dout_valid(dout_valid_stage2)
);

assign din_re_stage2 = dout_re_stage8_r;
assign din_im_stage2 = dout_im_stage8_r;
assign din_valid_stage2 = dout_valid_stage8_r;

wire signed [25:0] dout_re_stage2_r, dout_im_stage2_r;
wire dout_valid_stage2_r;

delay #(
    .DATA_WIDTH(53),
    .DELAY_VALUE(0)
) delay_stage2 (
    .clk(clk),
    .din({dout_re_stage2, dout_im_stage2, dout_valid_stage2 }),
    .dout({dout_re_stage2_r, dout_im_stage2_r, dout_valid_stage2_r })
);

assign dout_re = dout_re_stage2_r;
assign dout_im = dout_im_stage2_r;
assign dout_valid = dout_valid_stage2_r;

endmodule