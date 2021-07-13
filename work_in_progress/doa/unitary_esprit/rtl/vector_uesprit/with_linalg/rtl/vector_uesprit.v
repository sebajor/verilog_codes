`default_nettype none
//`include "./rtl/correlation_matrix.v"
//`include "./rtl/centrosym_matrix.v"
//`include "includes.v"

module vector_uesprit #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    //correlation matrix parameters
    parameter VECTOR_LEN = 64,
    parameter ACC_WIDTH = 20,
    parameter ACC_POINT = 16,
    parameter DOUT_WIDTH = 32
) (
    input wire clk,

    input wire signed [DIN_WIDTH-1:0] din1_re, din1_im,
    input wire signed [DIN_WIDTH-1:0] din2_re, din2_im,
    input wire din_valid,
    
    input wire new_acc,
    output wire signed [DOUT_WIDTH-1:0] r11, r22, r12_re, r12_im,
    output wire dout_valid 
);

//register everything for timing
reg [DIN_WIDTH-1:0] din1re=0, din1im=0, din2re=0, din2im =0;
reg dinvalid=0;
always@(posedge clk)begin
    din1re <= din1_re;  din1im<=din1_im;
    din2re <= din2_re;  din2im<=din2_im;
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

//correlation matrix
correlation_matrix #(
    .DIN_WIDTH(DIN_WIDTH+1),
    .DIN_POINT(DIN_POINT),
    .VECTOR_LEN(VECTOR_LEN),
    .ACC_WIDTH(ACC_WIDTH),
    .ACC_POINT(ACC_POINT),
    .DOUT_WIDTH(DOUT_WIDTH)
)corr_matrix_inst (
    .clk(clk),
    .rst(1'b0),
    .new_acc(new_acc_r[2]),
    .din1_re(y1_re),
    .din1_im(y1_im),
    .din2_re(y2_re),
    .din2_im(y2_im),
    .din_valid(y_valid),
    .r11(r11),
    .r22(r22),
    .r12_re(r12_re),
    .r12_im(r12_im),
    .dout_valid(dout_valid)
);



endmodule
