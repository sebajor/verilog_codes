`default_nettype none
`include "includes.v"

module scalar_uesprit #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    parameter ACC_WIDTH = 25,
    parameter ACC_POINT = 14,
    parameter DOUT_WIDTH = 32
) (
    input wire clk,
    input wire new_acc,

    input wire [DIN_WIDTH-1:0] din1_re, din1_im,
    input wire [DIN_WIDTH-1:0] din2_re, din2_im,
    input wire din_valid,
    
    output wire [DOUT_WIDTH-1:0] r11, r22, r12_re, r12_im,
    output wire dout_valid
);

//register inputs for timing 
reg [DIN_WIDTH-1:0] din1re=0, din1im=0, din2re=0, din2im=0;
reg dinvalid=0;
always@(posedge clk)begin
    din1re <= din1_re;  din1im <= din1_im;
    din2re <= din2_re;  din2im <= din2_im;
    dinvalid <= din_valid;
end

//centrosymetric transformation
wire [DIN_WIDTH:0] y1_re, y1_im, y2_re, y2_im;
wire y_valid;

centrosym_matrix #(
    .DIN_WIDTH(DIN_WIDTH)
) centro_sym_transf_inst (
    .clk(clk),
    .din1_re(din1re),
    .din1_im(din1im),
    .din2_re(din2re),
    .din2_im(din2im),
    .din_valid(dinvalid),
    .y1_re(y1_re),
    .y1_im(y1_im),
    .y2_re(y2_re),
    .y2_im(y2_im),
    .dout_valid(y_valid)
);

//align new_acc with the data
reg [2:0] new_acc_r =0;
always@(posedge clk)begin
    new_acc_r <= {new_acc_r[1:0], new_acc}; //check!!
end

//correlation multiplications
//6 cycles delays ?
wire [2*(DIN_WIDTH+1):0] y1_pow, y2_pow;
wire signed [2*(DIN_WIDTH+1):0] ycorr_re, ycorr_im;
wire corr_valid;

correlation_mults #(
    .DIN_WIDTH(DIN_WIDTH+1)
)corr_mults_inst (
    .clk(clk),
    .rst(1'b0),
    .din1_re(y1_re),
    .din1_im(y1_im),
    .din2_re(y2_re),
    .din2_im(y2_im),
    .din_valid(y_valid),
    .din1_pow(y1_pow),
    .din2_pow(y2_pow),
    .corr_re(ycorr_re),
    .corr_im(ycorr_im),
    .dout_valid(corr_valid)
);

//cast the output to ACC_WIDTH size
localparam CORR_POINT = 2*DIN_POINT;
localparam CORR_WIDTH = 2*(DIN_WIDTH+1)+1;
localparam CORR_INT = CORR_WIDTH-CORR_POINT;
localparam ACC_INT = ACC_WIDTH-ACC_POINT;

wire signed [ACC_WIDTH-1:0] acc_corr_re, acc_corr_im;
wire acc_corr_valid;

signed_cast #(
    .PARALLEL(2),
    .DIN_WIDTH(CORR_WIDTH),
    .DIN_INT(CORR_INT),
    .DOUT_WIDTH(ACC_WIDTH),
    .DOUT_INT(ACC_INT)
) corr_cast (
    .clk(clk),
    .din({ycorr_re, ycorr_im}),
    .din_valid(corr_valid),
    .dout({acc_corr_re, acc_corr_im}),
    .dout_valid(acc_corr_valid)
);

//for the unsigned is easier
reg [ACC_WIDTH-1:0] acc_pow1=0, acc_pow2=0;
reg acc_pow_valid=0;
always@(posedge clk)begin
    acc_pow1 <= y1_pow[CORR_POINT+ACC_INT-1-:ACC_WIDTH];
    acc_pow2 <= y2_pow[CORR_POINT+ACC_INT-1-:ACC_WIDTH];
    acc_pow_valid <= corr_valid;
end

//match the delays again
reg [7:0] new_acc_rr=0;
always@(posedge clk)begin
    new_acc_rr <= {new_acc_rr[6:0], new_acc_r};
end
wire new_acc_scalar;
assign new_acc_scalar = new_acc_rr[7];


//accumulators

wire signed [DOUT_WIDTH-1:0] corr_re_out, corr_im_out;
wire corr_out_valid;

signed_acc #(
    .DIN_WIDTH(ACC_WIDTH),
    .ACC_WIDTH(DOUT_WIDTH)
)corr_acc_re_inst (
    .clk(clk),
    .din(acc_corr_re),
    .din_valid(acc_corr_valid),
    .acc_done(new_acc_scalar),
    .dout(corr_re_out),
    .dout_valid(corr_out_valid)
);

signed_acc #(
    .DIN_WIDTH(ACC_WIDTH),
    .ACC_WIDTH(DOUT_WIDTH)
)corr_acc_im_inst (
    .clk(clk),
    .din(acc_corr_im),
    .din_valid(acc_corr_valid),
    .acc_done(new_acc_scalar),
    .dout(corr_im_out),
    .dout_valid()
);


//unsigned accumulation
wire [DOUT_WIDTH-1:0] pow1_out, pow2_out;

unsig_acc #(
    .DIN_WIDTH(ACC_WIDTH),
    .ACC_WIDTH(DOUT_WIDTH)
) pow1_vacc (
    .clk(clk),
    .acc_done(new_acc_scalar),
    .din(acc_pow1),
    .din_valid(acc_pow_valid),
    .dout(pow1_out),
    .dout_valid()
);

unsig_acc #(
    .DIN_WIDTH(ACC_WIDTH),
    .ACC_WIDTH(DOUT_WIDTH)
) pow2_vacc (
    .clk(clk),
    .acc_done(new_acc_scalar),
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
