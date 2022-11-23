`default_nettype none

/*
*   Author: Sebastian Jorquera
*/

module correlator_lane #(
    parameter DIN_WIDTH = 18,
    parameter DIN_POINT = 17,
    parameter VECTOR_LEN = 512,
    parameter MULT_DOUT = 2*DIN_WIDTH,
    parameter MULT_DELAY = 2,              //delay after the power computation
    parameter MULT_SHIFT = 0,
    parameter ACC_DIN_WIDTH = 2*DIN_WIDTH,
    parameter ACC_DIN_POINT = 2*DIN_POINT,
    parameter ACC_DOUT_WIDTH = 64,
    parameter DOUT_CAST_SHIFT = 0,
    parameter DOUT_CAST_DELAY = 0,
    parameter DOUT_WIDTH = 64,
    parameter DOUT_POINT = 2*DIN_POINT,
    parameter DEBUG = 0
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din0_re, din0_im, din1_re, din1_im,
    input wire din_valid,
    input wire sync_in,
    input wire [31:0] acc_len,
    input wire cnt_rst,

    output wire [DOUT_WIDTH-1:0] r11,r12_re, r12_im, r22,
    output wire dout_valid,
    output wire [$clog2(VECTOR_LEN)-1:0] dout_addr,
    output wire ovf_flag
);

//correlation mults
wire [2*DIN_WIDTH:0] din1_pow, din2_pow;
wire signed [2*DIN_WIDTH:0] corr_re, corr_im;
wire corr_valid;

correlation_mults #(
    .DIN_WIDTH(DIN_WIDTH)
) correlation_mults_inst (
    .clk(clk),
    .din1_re(din0_re),
    .din1_im(din0_im),
    .din2_re(din1_re),
    .din2_im(din1_im),
    .din_valid(din_valid),
    .din1_pow(din1_pow),
    .din2_pow(din2_pow),
    .corr_re(corr_re),
    .corr_im(corr_im),
    .dout_valid(corr_valid)
);

//just in case...
wire [MULT_DOUT:0] din1_pow_ = $unsigned(din1_pow);
wire [MULT_DOUT:0] din2_pow_ = $unsigned(din2_pow);

//delay the sync
wire sync_corr;
delay #(
    .DATA_WIDTH(1),
    .DELAY_VALUE(6)
) delay_power (
    .clk(clk),
    .din(sync_in),
    .dout(sync_corr)
);

//resize the outputs
wire [MULT_DOUT-1:0] pow1_acc, pow2_acc;
wire pow_acc_valid;
wire [1:0] pow_warning;

resize_data #(
    .DIN_WIDTH(MULT_DOUT+1),
    .DIN_POINT(2*DIN_POINT),
    .DATA_TYPE("unsigned"),
    .PARALLEL(1),
    .SHIFT(MULT_SHIFT),
    .DELAY(MULT_DELAY),
    .DOUT_WIDTH(ACC_DIN_WIDTH),
    .DOUT_POINT(ACC_DIN_POINT),
    .DEBUG(DEBUG)
) resize_powers [1:0] (
    .clk(clk), 
    .din({din1_pow_, din2_pow_}),
    .din_valid(corr_valid),
    .sync_in(),
    .dout({pow1_acc, pow2_acc}),
    .dout_valid(pow_acc_valid),
    .sync_out(),
    .warning(pow_warning)
);

wire signed [MULT_DOUT-1:0] corr_re_acc, corr_im_acc;
wire corr_acc_valid;
wire [1:0] corr_warning;
wire sync_acc;

resize_data #(
    .DIN_WIDTH(MULT_DOUT+1),
    .DIN_POINT(2*DIN_POINT),
    .DATA_TYPE("signed"),
    .PARALLEL(1),
    .SHIFT(MULT_SHIFT),
    .DELAY(MULT_DELAY),
    .DOUT_WIDTH(ACC_DIN_WIDTH),
    .DOUT_POINT(ACC_DIN_POINT),
    .DEBUG(DEBUG)
) resize_corrs [1:0] (
    .clk(clk), 
    .din({corr_re, corr_im}),
    .din_valid(corr_valid),
    .sync_in(sync_corr),
    .dout({corr_re_acc, corr_im_acc}),
    .dout_valid(corr_acc_valid),
    .sync_out(sync_acc),
    .warning(corr_warning)
);

//accumulation control signal
wire new_acc;

reg [31:0] frame_counter=0;
reg frame_en=0;
always@(posedge clk)begin
    if(cnt_rst)
        frame_en<=0;
    else if(sync_acc)
        frame_en <= 1;
end

always@(posedge clk)begin
    if(cnt_rst)
        frame_counter <=0;
    else if(frame_en)begin
        if(frame_counter == (acc_len<<$clog2(VECTOR_LEN))-1)
            frame_counter <=0;
        else
            frame_counter <= frame_counter+1;
    end
end

assign new_acc = (frame_counter == (acc_len<<$clog2(VECTOR_LEN))-1);

//accumulators
vector_accumulator #(
    .DIN_WIDTH(ACC_DIN_WIDTH),
    .VECTOR_LEN(VECTOR_LEN),
    .DOUT_WIDTH(ACC_DOUT_WIDTH),
    .DATA_TYPE("unsigned")
) vector_accumulator_unsign_inst [1:0] (
    .clk(clk),
    .new_acc(new_acc),
    .din({pow1_acc, pow2_acc}),
    .din_valid(pow_acc_valid),
    .dout({r11,r22}),
    .dout_valid()
);


//accumulators
wire vector_out_valid;
vector_accumulator #(
    .DIN_WIDTH(ACC_DIN_WIDTH),
    .VECTOR_LEN(VECTOR_LEN),
    .DOUT_WIDTH(ACC_DOUT_WIDTH),
    .DATA_TYPE("signed")
) vector_accumulator_sign_inst [1:0] (
    .clk(clk),
    .new_acc(new_acc),
    .din({corr_re_acc, corr_im_acc}),
    .din_valid(corr_acc_valid),
    .dout({r12_re,r12_im}),
    .dout_valid(vector_out_valid)
);

//counter
reg [$clog2(VECTOR_LEN)-1:0] addr_counter=0;
always@(posedge clk)begin
    if(new_acc)
        addr_counter <= 0;//{($clog2(VECTOR_LEN)){1'b1}};
    else if(vector_out_valid)
        addr_counter <= addr_counter+1;
end

assign dout_addr = addr_counter;
assign ovf_flag = (|corr_warning) | (|pow_warning);
assign dout_valid = vector_out_valid;

endmodule
