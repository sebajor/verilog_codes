`default_nettype none
`include "correlation_mults.v"
`include "includes.v"

/* 2x2 correlator in the freq domain
*/

module correlator #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    parameter VECTOR_LEN = 64,
    parameter ACC_WIDTH = 20,   //cast after the corr mults 
    parameter ACC_POINT = 16,
    parameter DOUT_WIDTH = 32 
) (
    input wire clk,
    input wire new_acc, //this signal comes before the first value of the frame

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

//cast output to ACC_WIDTH size
wire signed [ACC_WIDTH-1:0] acc_corr_re, acc_corr_im;
wire acc_corr_valid;

//1 cycle of delay
signed_cast #(
    .DIN_WIDTH(2*DIN_WIDTH+1),
    .DIN_POINT(2*DIN_POINT),
    .DOUT_WIDTH(ACC_WIDTH),
    .DOUT_POINT(ACC_POINT)
) cast_corr_re (
    .clk(clk), 
    .din(corr_re),
    .din_valid(corr_valid),
    .dout(acc_corr_re),
    .dout_valid(acc_corr_valid)
);

signed_cast #(
    .DIN_WIDTH(2*DIN_WIDTH+1),
    .DIN_POINT(2*DIN_POINT),
    .DOUT_WIDTH(ACC_WIDTH),
    .DOUT_POINT(ACC_POINT)
) cast_corr_im (
    .clk(clk), 
    .din(corr_im),
    .din_valid(corr_valid),
    .dout(acc_corr_im),
    .dout_valid()
);

//unsigned cast
//this is far from good.. but is logical that the ACC_INT > 2*DIN_INT, so 
//if the user is logical chosing the parameters it should work 
/*
localparam ACC_INT = ACC_WIDTH-ACC_POINT;
localparam CORR_POINT = 2*(DIN_WIDTH-DIN_POINT)+1; //check!

reg [ACC_WIDTH-1:0] acc_pow1=0, acc_pow2=0;
reg acc_pow_valid=0;
generate
    if(ACC_WIDTH<(2*DIN_WIDTH))begin
        always@(posedge clk) begin
            acc_pow1 <= din1_pow[CORR_POINT+ACC_INT-1-:ACC_WIDTH];
            acc_pow2 <= din2_pow[CORR_POINT+ACC_INT-1-:ACC_WIDTH];
            acc_pow_valid <= corr_valid;
        end
    end
    else if(ACC_WIDTH == 2*DIN_WIDTH)begin
        always@(posedge clk)begin
            acc_pow1 <= din1_pow;
            acc_pow2 <= din2_pow;
            acc_pow_valid <= corr_valid;
        end
    end
    else begin
        always@(posedge clk)begin
            acc_pow1 <= {{(2*DIN_WIDTH-CORR_POINT){1'b0}}, din1_pow};
            acc_pow2 <= {{(2*DIN_WIDTH-CORR_POINT){1'b0}}, din2_pow};
            acc_pow_valid <= corr_valid; 
        end
    end
endgenerate
*/

wire [ACC_WIDTH-1:0] acc_pow1, acc_pow2;
wire acc_pow_valid;

unsign_cast #(
    .DIN_WIDTH(2*DIN_WIDTH+1),
    .DIN_POINT(2*DIN_POINT),
    .DOUT_WIDTH(ACC_WIDTH),
    .DOUT_POINT(ACC_POINT)
) pow1_cast (
    .clk(clk), 
    .din(din1_pow),
    .din_valid(corr_valid),
    .dout(acc_pow1),
    .dout_valid(acc_pow_valid)
);

unsign_cast #(
    .DIN_WIDTH(2*DIN_WIDTH+1),
    .DIN_POINT(2*DIN_POINT),
    .DOUT_WIDTH(ACC_WIDTH),
    .DOUT_POINT(ACC_POINT)
) pow2_cast (
    .clk(clk), 
    .din(din2_pow),
    .din_valid(corr_valid),
    .dout(acc_pow2),
    .dout_valid()
);


//delay new acc to match the signals 
reg [7:0] new_acc_r=0;
always@(posedge clk)begin
    new_acc_r <= {new_acc_r[6:0], new_acc};
end
wire new_acc_vec = new_acc_r[7];

//accumulators 
wire signed [DOUT_WIDTH-1:0] corr_re_out, corr_im_out;
wire corr_out_valid;

signed_vacc #(
    .DIN_WIDTH(ACC_WIDTH),
    .VECTOR_LEN(VECTOR_LEN),
    .DOUT_WIDTH(DOUT_WIDTH)
) re_corr_vacc (
    .clk(clk),
    .new_acc(new_acc_vec),
    .din(acc_corr_re),
    .din_valid(acc_corr_valid),
    .dout(corr_re_out),
    .dout_valid(corr_out_valid)
);


signed_vacc #(
    .DIN_WIDTH(ACC_WIDTH),
    .VECTOR_LEN(VECTOR_LEN),
    .DOUT_WIDTH(DOUT_WIDTH)
) im_corr_vacc (
    .clk(clk),
    .new_acc(new_acc_vec),
    .din(acc_corr_im),
    .din_valid(acc_corr_valid),
    .dout(corr_im_out),
    .dout_valid()
);

wire [DOUT_WIDTH-1:0] pow1_out, pow2_out;

unsign_vacc #(
    .DIN_WIDTH(ACC_WIDTH),
    .DOUT_WIDTH(DOUT_WIDTH),
    .VECTOR_LEN(VECTOR_LEN)
) pow1_vacc (
    .clk(clk),
    .new_acc(new_acc_vec),
    .din(acc_pow1),
    .din_valid(acc_pow_valid),
    .dout(pow1_out),
    .dout_valid()
);

unsign_vacc #(
    .DIN_WIDTH(ACC_WIDTH),
    .DOUT_WIDTH(DOUT_WIDTH),
    .VECTOR_LEN(VECTOR_LEN)
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
