`default_nettype none

module pointwise_vector_doa #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    //correlator parameters
    parameter VECTOR_LEN = 64,
    parameter ACC_WIDTH = 20,
    parameter ACC_POINT = 16,
    parameter ACC_DOUT_WIDTH = 32,
    //linear algebra parameters
    parameter ACC_SHIFT = 2,    //positive <<, negative >>
    parameter EIGEN_IN_WIDTH = 16,
    parameter EIGEN_IN_POINT = 15,
    parameter SQRT_IN_WIDTH = 10,
    parameter SQRT_IN_POINT = 7,
    parameter SQRT_OUT_WIDTH = 16,
    parameter SQRT_OUT_POINT = 13,
    parameter SQRT_MEM_FILE = "sqrt.mem",
    parameter DOUT_WIDTH = 16,
    parameter DOUT_POINT = 13
) (
    input wire clk,
    input wire new_acc, 
    
    input wire signed [DIN_WIDTH-1:0] din1_re, din1_im,
    input wire signed [DIN_WIDTH-1:0] din2_re, din2_im,
    input wire din_valid,

    output wire signed [DOUT_WIDTH-1:0] lamb1, lamb2,
    output wire signed [DOUT_WIDTH-1:0] eigen1_y, eigen2_y, eigen_x,
    //the correct eigen value is eigen_y/eigen_x, but the output of this
    //module goes into a arctan so we are happy with that :)
    output wire dout_valid,
    output wire dout_error

);


wire signed [ACC_DOUT_WIDTH-1:0] r11,r22,r12_re,r12_im;
wire corr_valid;

point_doa_no_la #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .VECTOR_LEN(VECTOR_LEN),
    .ACC_WIDTH(ACC_WIDTH),
    .ACC_POINT(ACC_POINT),
    .DOUT_WIDTH(ACC_DOUT_WIDTH)
) point_doa_no_la_inst (
    .clk(clk),
    .din1_re(din1_re),
    .din1_im(din1_im),
    .din2_re(din2_re),
    .din2_im(din2_im),
    .din_valid(din_valid),
    .new_acc(new_acc),
    .r11(r11),
    .r22(r22),
    .r12_re(r12_re),
    .r12_im(r12_im),
    .dout_valid(corr_valid)
);

wire signed [ACC_DOUT_WIDTH-1:0] r11_r, r22_r, r12_r;
wire corr_valid_r;

generate 

reg signed [ACC_DOUT_WIDTH-1:0] r11_reg=0, r22_reg=0, r12_reg=0;
reg corr_valid_reg=0;
assign r11_r = r11_reg;
assign r12_r = r12_reg;
assign r22_r = r22_reg;
assign corr_valid_r = corr_valid_reg;

if(ACC_SHIFT==0)begin
    always@(posedge clk)begin
        r11_reg <= r11;
        r22_reg <= r22;
        r12_reg <= r12_re;
        corr_valid_reg <= corr_valid;
    end
end
else if(ACC_SHIFT<0)begin
    always@(posedge clk)begin
        r11_reg <= r11>>>(-ACC_SHIFT);
        r22_reg <= r22>>>(-ACC_SHIFT);
        r12_reg <= r12_re>>>(-ACC_SHIFT);
        corr_valid_reg <= corr_valid;
    end
end
else begin
    always@(posedge clk)begin
        r11_reg <= r11<<<(ACC_SHIFT);
        r22_reg <= r22<<<(ACC_SHIFT);
        r12_reg <= r12_re<<<(ACC_SHIFT);
        corr_valid_reg <= corr_valid;
    end
end
endgenerate

wire signed [EIGEN_IN_WIDTH-1:0] r11_cast, r22_cast, r12_cast;
wire [2:0] corr_cast_valid;

signed_cast #(
    .DIN_WIDTH(ACC_DOUT_WIDTH),
    .DIN_POINT(ACC_POINT),
    .DOUT_WIDTH(EIGEN_IN_WIDTH),
    .DOUT_POINT(EIGEN_IN_POINT)
)corr_cast_inst [2:0] (
    .clk(clk), 
    .din({r11_r,r22_r,r12_r}),
    .din_valid(corr_valid_r),
    .dout({r11_cast, r22_cast, r12_cast}),
    .dout_valid(corr_cast_valid)
);


quad_eigen #(
    .DIN_WIDTH(EIGEN_IN_WIDTH),
    .DIN_POINT(EIGEN_IN_POINT),
    .SQRT_IN_WIDTH(SQRT_IN_WIDTH),
    .SQRT_IN_POINT(SQRT_IN_POINT),
    .SQRT_OUT_WIDTH(SQRT_OUT_WIDTH),
    .SQRT_OUT_POINT(SQRT_OUT_POINT),
    .SQRT_MEM_FILE(SQRT_MEM_FILE),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT)
) quad_eigen_inst (
    .clk(clk),
    .r11(r11_cast), 
    .r22(r22_cast),
    .r12(r12_cast),
    .din_valid(corr_cast_valid[0]),
    .lamb1(lamb1),
    .lamb2(lamb2),
    .eigen1_y(eigen1_y),
    .eigen2_y(eigen2_y),
    .eigen_x(eigen_x),
    .dout_valid(dout_valid),
    .dout_error(dout_error)
);


endmodule
