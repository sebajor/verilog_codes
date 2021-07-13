`default_nettype none
//`include "correlation_mults.v"
//`include "signed_cast.v"
//`include "signed_vector_acc.v"
//`include "unsigned_vector_acc.v"


module correlation_matrix #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    parameter VECTOR_LEN = 64,
    parameter ACC_WIDTH = 20,
    parameter ACC_POINT = 16,
    parameter DOUT_WIDTH = 32
) (
    input wire clk,
    input wire rst,

    input wire new_acc, //this one should come before the first valid value of 
                        //the frame
    input wire signed [DIN_WIDTH-1:0] din1_re, din1_im,
    input wire signed [DIN_WIDTH-1:0] din2_re, din2_im,
    input wire din_valid,

    output wire [DOUT_WIDTH-1:0] r11, r22, r12_re, r12_im,
    output wire dout_valid
);


wire [2*DIN_WIDTH:0] din1_pow, din2_pow;
wire signed [2*DIN_WIDTH:0] corr_re, corr_im;
wire corr_valid;

//6 cycles delay?
correlation_mults #(
    .DIN_WIDTH(DIN_WIDTH)
) corr_mults (
    .clk(clk),
    .rst(rst),
    .din1_re(din1_re),
    .din1_im(din1_im),
    .din2_re(din2_re),
    .din2_im(din2_im),
    .din_valid(din_valid),
    .din1_pow(din1_pow),
    .din2_pow(din2_pow),
    .corr_re(corr_re),
    .corr_im(corr_im),
    .dout_valid(corr_valid)
);


//cast the output to ACC_WIDTH size

localparam CORR_POINT = 2*DIN_POINT;
localparam CORR_WIDTH = 2*DIN_WIDTH+1;
localparam CORR_INT = CORR_WIDTH-CORR_POINT;
localparam ACC_INT = ACC_WIDTH-ACC_POINT;

wire signed [ACC_WIDTH-1:0] acc_corr_re, acc_corr_im;
wire acc_corr_valid;

//1 cycle of delay; check!
signed_cast #(
    .PARALLEL(2),
    .DIN_WIDTH(CORR_WIDTH),
    .DIN_INT(CORR_INT),
    .DOUT_WIDTH(ACC_WIDTH),
    .DOUT_INT(ACC_INT)
) corr_cast (
    .clk(clk),
    .din({corr_re, corr_im}),
    .din_valid(corr_valid),
    .dout({acc_corr_re, acc_corr_im}),
    .dout_valid(acc_corr_valid)
);

//for the unsigned is easier
reg [ACC_WIDTH-1:0] acc_pow1=0, acc_pow2=0;
reg acc_pow_valid=0;
always@(posedge clk)begin
    acc_pow1 <= din1_pow[CORR_POINT+ACC_INT-1-:ACC_WIDTH];
    acc_pow2 <= din2_pow[CORR_POINT+ACC_INT-1-:ACC_WIDTH];
    acc_pow_valid <= corr_valid;
end

//accumulators

//to match the new acc with the involved delays (check!)
reg [7:0] new_acc_r=0;
always@(posedge clk)begin
    new_acc_r <= {new_acc_r[6:0], new_acc};
end

wire new_acc_vec;
assign new_acc_vec = new_acc_r[7];

wire signed [DOUT_WIDTH-1:0] corr_re_out, corr_im_out;
wire corr_out_valid;

//the vacc's start to change one cycle after the dout_valid is asserted
//thats not a bug, the data thats is constant before it is the 0 addr value
//as some folk say: its not a bug is a feature

signed_vector_acc #(
    .DIN_WIDTH(ACC_WIDTH),
    .VECTOR_LEN(VECTOR_LEN),
    .DOUT_WIDTH(DOUT_WIDTH)
) corr_re_vacc (
    .clk(clk),
    .new_acc(new_acc_vec),
    .din(acc_corr_re),
    .din_valid(acc_corr_valid),
    .dout(corr_re_out),
    .dout_valid(corr_out_valid)
);

signed_vector_acc #(
    .DIN_WIDTH(ACC_WIDTH),
    .VECTOR_LEN(VECTOR_LEN),
    .DOUT_WIDTH(DOUT_WIDTH)
) corr_im_vacc (
    .clk(clk),
    .new_acc(new_acc_vec),
    .din(acc_corr_im),
    .din_valid(acc_corr_valid),
    .dout(corr_im_out),
    .dout_valid()
);

//unsigned acc for the powers
wire [DOUT_WIDTH-1:0] pow1_out, pow2_out;

unsigned_vector_acc #(
    .DIN_WIDTH(ACC_WIDTH),
    .VECTOR_LEN(VECTOR_LEN),
    .DOUT_WIDTH(DOUT_WIDTH)
) pow1_vacc (
    .clk(clk),
    .new_acc(new_acc_vec),
    .din(acc_pow1),
    .din_valid(acc_pow_valid),
    .dout(pow1_out),
    .dout_valid()
);

unsigned_vector_acc #(
    .DIN_WIDTH(ACC_WIDTH),
    .VECTOR_LEN(VECTOR_LEN),
    .DOUT_WIDTH(DOUT_WIDTH)
) pow2_vacc (
    .clk(clk),
    .new_acc(new_acc_vec),
    .din(acc_pow2),
    .din_valid(acc_pow_valid),
    .dout(pow2_out),
    .dout_valid()
);



assign r11 = pow1_out;
assign r22 = pow2_out;
assign r12_re = corr_re_out;
assign r12_im = corr_im_out;

assign dout_valid = corr_out_valid;


endmodule 
