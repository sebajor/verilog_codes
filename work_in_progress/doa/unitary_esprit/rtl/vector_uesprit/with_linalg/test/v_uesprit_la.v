`default_nettype none
`include "includes.v"

module v_uesprit_la #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    //correlation matrix parameters
    parameter VECTOR_LEN = 64,
    parameter CORR_WIDTH = 20,
    parameter CORR_POINT = 16,
    parameter CORR_DOUT_WIDTH = 32,
    //linear algebra parameters
    parameter LA_IN_WIDTH = 16,
    parameter LA_IN_POINT = 15,
    parameter SQRT_IN_WIDTH = 10,
    parameter SQRT_IN_POINT = 7,
    parameter DOUT_WIDTH = 16,
    parameter DOUT_POINT = 13
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din1_re, din1_im,
    input wire signed [DIN_WIDTH-1:0] din2_re, din2_im,
    input wire din_valid,
    input wire new_acc,
    
    //for debugging
    input wire [4:0] shift,
    output wire signed [LA_IN_WIDTH-1:0] r11, r22, r12_re, r12_im,
    output wire corr_valid,
    
    //linear algebra outputs
    output wire signed [DOUT_WIDTH-1:0] lamb1, lamb2,
    output wire signed [DOUT_WIDTH-1:0] eigen1_y, eigen2_y, eigen_x,
    output wire dout_valid
);

wire signed [CORR_DOUT_WIDTH-1:0] corr_r11, corr_r22, corr_r12re, corr_r12im;
wire corr_mat_valid;

vector_uesprit #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .VECTOR_LEN(VECTOR_LEN),
    .ACC_WIDTH(CORR_WIDTH),
    .ACC_POINT(CORR_POINT),
    .DOUT_WIDTH(CORR_DOUT_WIDTH)
) vector_uesprit_inst (
    .clk(clk),
    .din1_re(din1_re),
    .din1_im(din1_im),
    .din2_re(din2_re),
    .din2_im(din2_im),
    .din_valid(din_valid),
    .new_acc(new_acc),
    .r11(corr_r11),
    .r22(corr_r22),
    .r12_re(corr_r12re),
    .r12_im(corr_r12im),
    .dout_valid(corr_mat_valid)
);


//shift the correlation output to match the eigen input
reg signed [CORR_DOUT_WIDTH-1:0] r11_r=0, r22_r=0, r12_re_r=0, r12_im_r=0;
reg corr_valid_r=0;
always@(posedge clk)begin
    corr_valid_r <= corr_mat_valid;
    r11_r <= corr_r11>>>(shift);
    r22_r <= corr_r22>>>(shift);
    r12_re_r <= corr_r12re>>>(shift);
    r12_im_r <= corr_r12im>>>(shift);
end

localparam LA_IN_INT = LA_IN_WIDTH-LA_IN_POINT;
//localparam AUX_INT = CORR_DOUT_WIDTH-LA_IN_POINT;
wire signed [LA_IN_WIDTH-1:0] r11_cast, r22_cast,r12re_cast,r12im_cast;
wire corr_cast_valid;

/*
signed_cast #(
    .PARALLEL(4),
    .DIN_WIDTH(CORR_DOUT_WIDTH),
    .DIN_INT(2),
    .DOUT_WIDTH(LA_IN_WIDTH),
    .DOUT_INT(LA_IN_INT)
) corr_cast (
    .clk(clk),
    .din({r11_r,r22_r,r12_re_r,r12_im_r}),
    .din_valid(corr_valid_r),
    .dout({r11_cast, r22_cast,r12re_cast,r12im_cast}),
    .dout_valid(corr_cast_valid)
);
*/
//debug only
wire ovf_r11 = ((~r11_r[CORR_DOUT_WIDTH-1] & (| r11_r[CORR_DOUT_WIDTH-2:CORR_POINT+1]))
                | (r11_r[CORR_DOUT_WIDTH-1] & (~(&r11_r[CORR_DOUT_WIDTH-2:CORR_POINT+1]))));

wire ovf_r22 = ((~r22_r[CORR_DOUT_WIDTH-1] & (| r22_r[CORR_DOUT_WIDTH-2:CORR_POINT+1]))
                | (r22_r[CORR_DOUT_WIDTH-1] & (~(&r22_r[CORR_DOUT_WIDTH-2:CORR_POINT+1]))));

wire ovf_r12 = ((~r12_re_r[CORR_DOUT_WIDTH-1] & (| r12_re_r[CORR_DOUT_WIDTH-2:CORR_POINT+1]))
                | (r12_re_r[CORR_DOUT_WIDTH-1] & (~(&r12_re_r[CORR_DOUT_WIDTH-2:CORR_POINT+1]))));

reg [$clog2(VECTOR_LEN)-1:0] counter=0;
always@(posedge clk)begin
    if(corr_cast_valid)
        counter <= counter+1;
end
//wire ovf_r22 = 
//wire ovf_r12 = 

assign r11_cast = r11_r[CORR_POINT+1-:LA_IN_WIDTH];
assign r22_cast = r22_r[CORR_POINT+1-:LA_IN_WIDTH];
assign r12re_cast = r12_re_r[CORR_POINT+1-:LA_IN_WIDTH];
assign r12im_cast = r12_im_r[CORR_POINT+1-:LA_IN_WIDTH];
assign corr_cast_valid = corr_valid_r;

assign r11 = r11_cast;
assign r22 = r22_cast;
assign r12_re = r12re_cast;
assign r12_im = r12im_cast;
assign corr_valid = corr_cast_valid;



eigen #(
    .DIN_WIDTH(LA_IN_WIDTH),
    .DIN_POINT(LA_IN_WIDTH-1),
    .SQRT_IN_WIDTH(SQRT_IN_WIDTH),
    .SQRT_IN_POINT(SQRT_IN_POINT),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT)
) eigen_inst (
    .clk(clk),
    .r11(r11_cast), 
    .r22(r22_cast),
    .r12(r12re_cast),
    .din_valid(corr_cast_valid),
    .lamb1(lamb1),
    .lamb2(lamb2),
    .eigen1_y(eigen1_y),
    .eigen2_y(eigen2_y),
    .eigen_x(eigen_x),
    .dout_valid(dout_valid)
);


endmodule
