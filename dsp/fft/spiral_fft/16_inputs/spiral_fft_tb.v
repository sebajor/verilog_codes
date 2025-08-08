//`default_nettype none
`include "spiral_fft.v"


module spiral_fft_tb (
    input wire clk,
    input wire reset,
    input wire  next,
    output wire next_out,
    input wire signed [15:0] X0_re,X0_im, X1_re,X1_im, X2_re,X2_im, X3_re,X3_im,
                             X4_re,X4_im, X5_re,X5_im, X6_re,X6_im, X7_re,X7_im,
                             X8_re,X8_im, X9_re,X9_im, X10_re,X10_im, X11_re,X11_im,
                             X12_re,X12_im, X13_re,X13_im, X14_re,X14_im, X15_re,X15_im,



    output wire signed [15:0]  Y0_re,Y0_im, Y1_re,Y1_im, Y2_re,Y2_im, Y3_re,Y3_im,
                               Y4_re,Y4_im, Y5_re,Y5_im, Y6_re,Y6_im, Y7_re,Y7_im,
                               Y8_re,Y8_im, Y9_re,Y9_im, Y10_re,Y10_im, Y11_re,Y11_im,
                               Y12_re,Y12_im, Y13_re,Y13_im, Y14_re,Y14_im, Y15_re,Y15_im
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
    .X16(X8_re),
    .X17(X8_im),
    .X18(X9_re),
    .X19(X9_im),
    .X20(X10_re),
    .X21(X10_im),
    .X22(X11_re),
    .X23(X11_im),
    .X24(X12_re),
    .X25(X12_im),
    .X26(X13_re),
    .X27(X13_im),
    .X28(X14_re),
    .X29(X14_im),
    .X30(X15_re),
    .X31(X15_im),

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
    .Y15(Y7_im),
    
    .Y16(Y8_re),
    .Y17(Y8_im),
    .Y18(Y9_re),
    .Y19(Y9_im),
    .Y20(Y10_re),
    .Y21(Y10_im),
    .Y22(Y11_re),
    .Y23(Y11_im),
    .Y24(Y12_re),
    .Y25(Y12_im),
    .Y26(Y13_re),
    .Y27(Y13_im),
    .Y28(Y14_re),
    .Y29(Y14_im),
    .Y30(Y15_re),
    .Y31(Y15_im)
);

reg [31:0] counter=0;
always@(posedge clk)begin
    if(next_out)
        counter <=0;
    else 
        counter <= counter+1;

end

endmodule
