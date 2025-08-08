//`default_nettype none
`include "spiral_fft.v"


module spiral_fft_tb (
    input wire clk,
    input wire reset,
    input wire  next,
    output wire next_out,
    input wire signed [15:0] X0_re,X0_im, X1_re,X1_im, X2_re,X2_im, X3_re,X3_im,
                             X4_re,X4_im, X5_re,X5_im, X6_re,X6_im, X7_re,X7_im,
    output wire signed [15:0]  Y0_re,Y0_im, Y1_re,Y1_im, Y2_re,Y2_im, Y3_re,Y3_im,
                               Y4_re,Y4_im, Y5_re,Y5_im, Y6_re,Y6_im, Y7_re,Y7_im
);


dft_top dft_top_inst(
    .clk(clk), 
    .reset(reset), 
    .next(next), 
    .next_out(next_out),
    .X0(X0_re),
    .X1(X0_im),
    .X2(X1_re),
    .X3(X1_im),
    .X4(X2_re),
    .X5(X2_im),
    .X6(X3_re),
    .X7(X3_im),
    .X8(X4_re),
    .X9(X4_im),
    .X10(X5_re),
    .X11(X5_im),
    .X12(X6_re),
    .X13(X6_im),
    .X14(X7_re),
    .X15(X7_im),
    .Y0(Y0_re),
    .Y1(Y0_im),
    .Y2(Y1_re),
    .Y3(Y1_im),
    .Y4(Y2_re),
    .Y5(Y2_im),
    .Y6(Y3_re),
    .Y7(Y3_im),
    .Y8(Y4_re),
    .Y9(Y4_im),
    .Y10(Y5_re),
    .Y11(Y5_im),
    .Y12(Y6_re),
    .Y13(Y6_im),
    .Y14(Y7_re),
    .Y15(Y7_im)
);

reg [31:0] counter=0;
always@(posedge clk)begin
    if(next_out)
        counter <=0;
    else 
        counter <= counter+1;

end

endmodule
