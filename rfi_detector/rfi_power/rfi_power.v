`default_nettype none

module rfi_power #(
    parameter DIN_WIDTH = 18,
    parameter DIN_POINT = 17,
    parameter CHANNEL_ADDR = 9,

    parameter POST_POW_DELAY = 0,
    parameter ACC_WIDTH = 64,
    //convert the output of the accumulator
    parameter POST_ACC_SHIFT = 0,
    parameter POST_ACC_WIDTH = 32,
    parameter POST_ACC_POINT = 16,
    parameter POST_ACC_DELAY = 0,
    parameter DOUT_SHIFT = 0,
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

wire [2*DIN_WIDTH:0] sig_pow, ref_pow;
wire [1:0] pow_valid;

complex_power #(
    .DIN_WIDTH(DIN_WIDTH)
) power_inst [1:0] (
    .clk(clk),
    .din_re({sig_re, ref_re}), 
    .din_im({sig_im, ref_im}),
    .din_valid(din_valid),
    .dout({sig_pow, ref_pow}),
    .dout_valid(pow_valid)
);

wire sync_delay;
delay #(
     .DATA_WIDTH(1),
     .DELAY_VALUE(4)
) pow_delay (
    .clk(clk),
    .din(sync_in),
    .dout(sync_delay)
);

//TODO see if we can share this..
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

//post power delay
wire [2*DIN_WIDTH:0] sig_pow_delay, ref_pow_delay;
wire pow_valid_delay, new_acc_delay;
delay #(
    .DATA_WIDTH(2*(2*DIN_WIDTH+1)+2),
     .DELAY_VALUE(POST_POW_DELAY)
) power_delay (
    .clk(clk),
    .din({sig_pow, ref_pow, pow_valid[0], new_acc}),
    .dout({sig_pow_delay, ref_pow_delay, pow_valid_delay, new_acc_delay})
);



//place vector accumulator
wire [ACC_WIDTH-1:0] acc_sig_pow, acc_ref_pow;
wire [1:0] acc_valid;

vector_accumulator #(
    .DIN_WIDTH(2*DIN_WIDTH+1),
    .VECTOR_LEN(2**CHANNEL_ADDR),
    .DOUT_WIDTH(ACC_WIDTH),
    .DATA_TYPE("unsigned")
) vacc_inst [1:0] (
    .clk(clk),
    .new_acc(new_acc_delay),
    .din({sig_pow_delay, ref_pow_delay}),
    .din_valid(pow_valid_delay),
    .dout({acc_sig_pow, acc_ref_pow}),
    .dout_valid(acc_valid)
);

wire [POST_ACC_WIDTH-1:0] sig_pow_cast, ref_pow_cast;
wire acc_cast_valid;
wire post_acc_warn;

resize_module #(
    .DIN_WIDTH(ACC_WIDTH),
    .DIN_POINT(2*DIN_POINT),
    .DATA_TYPE("unsigned"),
    .PARALLEL(2),
    .SHIFT(POST_ACC_SHIFT),
    .DELAY(POST_ACC_DELAY),
    .DOUT_WIDTH(POST_ACC_WIDTH),
    .DOUT_POINT(POST_ACC_POINT),
    .DEBUG(DEBUG)
) resize_acc (
    .clk(clk), 
    .din({acc_sig_pow, acc_ref_pow}),
    .din_valid(acc_valid[0]),
    .sync_in(),
    .dout({sig_pow_cast, ref_pow_cast}),
    .dout_valid(acc_cast_valid),
    .sync_out(),
    .warning(post_acc_warn)
);

wire [2*POST_ACC_WIDTH-1:0] dout_temp;
wire dout_valid_temp;

dsp48_mult #(
    .DIN1_WIDTH(POST_ACC_WIDTH),
    .DIN2_WIDTH(POST_ACC_WIDTH),
    .DOUT_WIDTH(2*POST_ACC_WIDTH)
) mult_inst (
    .clk(clk),
    .rst(1'b0),
    .din1(sig_pow_cast),
    .din2(ref_pow_cast),
    .din_valid(acc_cast_valid),
    .dout(dout_temp),
    .dout_valid(dout_valid_temp)
);

wire out_warn;
resize_module #(
    .DIN_WIDTH(2*POST_ACC_WIDTH),
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
    .din(dout_temp),
    .din_valid(dout_valid_temp),
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
