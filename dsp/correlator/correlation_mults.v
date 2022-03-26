`default_nettype none

/*
*   Author: Sebastian Jorquera
*   2x2 auto correlation and cross correlation in the frequency
*   in the frequency domain
*/

module correlation_mults #(
    parameter DIN_WIDTH = 18
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din1_re, din1_im,
    input wire signed [DIN_WIDTH-1:0] din2_re, din2_im,
    input wire din_valid,
    output wire [2*DIN_WIDTH:0] din1_pow, din2_pow,
    output wire signed [2*DIN_WIDTH:0] corr_re, corr_im,
    output wire dout_valid
);

reg [DIN_WIDTH-1:0] corr1_re = 0, corr1_im=0;
reg [DIN_WIDTH-1:0] din2re_conj=0, din2im_conj=0;

reg [DIN_WIDTH-1:0] din1re_r=0, din1im_r=0, din2re_r=0, din2im_r=0;
reg din_valid_r=0;
always@(posedge clk)begin
    din1re_r <= din1_re;    din1im_r <= din1_im;
    din2re_r <= din2_re;    din2im_r <= din2_im;
    din_valid_r <=din_valid;
    
    corr1_re <= din1_re;    corr1_im <= din1_im;
    din2re_conj <= din2_re; din2im_conj <= ~din2_im+1'b1;
end


//complex_power has 5 delay
wire [2*DIN_WIDTH:0] r11, r22;
wire r11_valid, r22_valid;

complex_power #(
    .DIN_WIDTH(DIN_WIDTH)
) pow1_mult (
    .clk(clk),
    .din_re(din1re_r),
    .din_im(din1im_r),
    .din_valid(din_valid_r),
    .dout(r11),
    .dout_valid(r11_valid)
);


complex_power #(
    .DIN_WIDTH(DIN_WIDTH)
) pow2_mult (
    .clk(clk),
    .din_re(din2re_r),
    .din_im(din2im_r),
    .din_valid(din_valid_r),
    .dout(r22),
    .dout_valid(r22_valid)
);


//correlation
//complex mult has 6 delay cycles
wire signed [2*DIN_WIDTH:0] corr_re_r, corr_im_r;
wire corr_valid;
complex_mult #(
    .DIN1_WIDTH(DIN_WIDTH),
    .DIN2_WIDTH(DIN_WIDTH)
) corr_mult (
    .clk(clk),
    .din1_re(corr1_re),
    .din1_im(corr1_im),
    .din2_re(din2re_conj),
    .din2_im(din2im_conj),
    .din_valid(din_valid_r),
    .dout_re(corr_re_r),
    .dout_im(corr_im_r),
    .dout_valid(corr_valid)
);


//delay to the powers to match the corr
reg [2*DIN_WIDTH:0] r11_r=0, r22_r=0;
always@(posedge clk)begin
    r11_r <= r11;
    r22_r <= r22;
end

//assign outputs (check timing!)
assign corr_re = corr_re_r;
assign corr_im = corr_im_r;
assign din1_pow = r11_r;
assign din2_pow = r22_r;
assign dout_valid = corr_valid;


endmodule
