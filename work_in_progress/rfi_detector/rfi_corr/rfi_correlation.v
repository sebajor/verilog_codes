`default_nettype none

module rfi_correlation #(
    parameter DIN_WIDTH = 18,
    parameter DIN_POINT = 17,
    parameter CHANNEL_ADDR = 9,
    //
    parameter POST_MULT_DELAY = 0,
    //
    parameter ACC_WIDTH = 32,
    parameter POST_ACC_SHIFT = 0,
    parameter POST_ACC_WIDTH = 32,
    parameter POST_ACC_POINT = 16,
    parameter POST_ACC_DELAY = 0,
    //
    parameter DOUT_SHIFT =0,
    parameter DOUT_WIDTH = 16,
    parameter DOUT_POINT = 12,
    parameter DEBUG = 1

) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] sig_re, sig_im, ref_re, ref_im,
    input wire din_valid,
    input wire sync_in,

    input wire [31:0] acc_len,
    input wire cnt_rst,

    output wire [DOUT_WIDTH-1:0] dout,
    output wire dout_valid,
    output wire warning
);


wire [DIN_WIDTH-1:0] ref_im_conj = ~ref_im+1'b1;
wire signed [2*DIN_WIDTH:0] cmult_re, cmult_im;
wire cmult_valid;

//6 cycles of delay
complex_mult #(
    .DIN1_WIDTH(DIN_WIDTH),
    .DIN2_WIDTH(DIN_WIDTH)
)complex_mult_inst (
    .clk(clk),
    .din1_re(sig_re),
    .din1_im(sig_im),
    .din2_re(ref_re),
    .din2_im(ref_im_conj),
    .din_valid(din_valid),
    .dout_re(cmult_re),
    .dout_im(cmult_im),
    .dout_valid(cmult_valid)
);

wire sync_delay;
delay #(
    .DATA_WIDTH(1),
    .DELAY_VALUE(5)
) cmult_delay (
    .clk(clk),
    .din(sync_in),
    .dout(sync_delay)
);


wire new_acc;
acc_control #(
    .CHANNEL_ADDR(CHANNEL_ADDR)
) acc_control_inst (
    .clk(clk),
    .sync_in(sync_delay),
    .acc_len(acc_len),
    .rst(cnt_rst),
    .new_acc(new_acc)
);


//delay the cmult output
wire signed [2*DIN_WIDTH:0] data_re, data_im;
wire data_valid, new_acc_data;
delay #(
    .DATA_WIDTH(2*(2*DIN_WIDTH+1)+2),
    .DELAY_VALUE(POST_MULT_DELAY)
) cdata_delay (
    .clk(clk),
    .din({cmult_re,cmult_im, cmult_valid,new_acc}),
    .dout({data_re, data_im, data_valid, new_acc_data})
);

//accumulate the complex output
wire signed [ACC_WIDTH-1:0] acc_re, acc_im;
wire signed [1:0] acc_valid;

vector_accumulator #(
    .DIN_WIDTH(2*DIN_WIDTH+1),
    .VECTOR_LEN(2**CHANNEL_ADDR),
    .DOUT_WIDTH(ACC_WIDTH),
    .DATA_TYPE("signed")
) vacc_inst [1:0] (
    .clk(clk),
    .new_acc(new_acc_data),
    .din({data_re, data_im}),
    .din_valid(data_valid),
    .dout({acc_re, acc_im}),
    .dout_valid(acc_valid)
);

wire acc_cast_valid;
wire [POST_ACC_WIDTH-1:0] acc_re_cast, acc_im_cast;
wire post_acc_warn;

resize_module #(
    .DIN_WIDTH(ACC_WIDTH),
    .DIN_POINT(2*DIN_POINT),
    .DATA_TYPE("signed"),
    .PARALLEL(2),
    .SHIFT(POST_ACC_SHIFT),
    .DELAY(POST_ACC_DELAY),
    .DOUT_WIDTH(POST_ACC_WIDTH),
    .DOUT_POINT(POST_ACC_POINT),
    .DEBUG(DEBUG)
) resize_acc (
    .clk(clk), 
    .din({acc_re, acc_im}),
    .din_valid(acc_valid[0]),
    .sync_in(),
    .dout({acc_re_cast, acc_im_cast}),
    .dout_valid(acc_cast_valid),
    .sync_out(),
    .warning(post_acc_warn)
);


wire [2*POST_ACC_WIDTH:0] pow_data;
wire pow_valid;

complex_power #(
    .DIN_WIDTH(POST_ACC_WIDTH)
) power_inst (
    .clk(clk),
    .din_re(acc_re_cast), 
    .din_im(acc_im_cast),
    .din_valid(acc_cast_valid),
    .dout(pow_data),
    .dout_valid(pow_valid)
);


wire out_warn;

resize_module #(
    .DIN_WIDTH(2*POST_ACC_WIDTH+1),
    .DIN_POINT(2*POST_ACC_POINT),
    .DATA_TYPE("unsigned"),
    .PARALLEL(1),
    .SHIFT(DOUT_SHIFT),
    .DELAY(0),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT),
    .DEBUG(DEBUG)
) resize_dout (
    .clk(clk), 
    .din(pow_data),
    .din_valid(pow_valid),
    .sync_in(),
    .dout(dout),
    .dout_valid(dout_valid),
    .sync_out(),
    .warning(out_warn)
);

generate
if(DEBUG)
    assign warning = (out_warn |post_acc_warn);
else
    assign warning =0;
endgenerate

endmodule
