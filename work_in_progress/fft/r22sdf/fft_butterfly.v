`default_nettype none

module fft_butterfly #( 
    parameter DIN_WIDTH = 16,
    parameter ROUND_UP = 1,
    parameter SCALE = 1
) (
    input wire signed [DIN_WIDTH-1:0] din0_re, din0_im,
    input wire signed [DIN_WIDTH-1:0] din1_re, din1_im,
    output wire signed [DIN_WIDTH-1:0] dout0_re, dout0_im,
    output wire signed [DIN_WIDTH-1:0] dout1_re, dout1_im
);

wire signed [DIN_WIDTH:0] add_re, add_im, sub_re, sub_im;

assign add_re = (din0_re+din1_re);
assign add_im = (din0_im+din1_im);
assign sub_re = (din0_re-din1_re);
assign sub_im = (din0_im-din1_im);

generate
    if(SCALE)begin
        assign dout0_re = (add_re+ROUND_UP)>>>1;
        assign dout0_im = (add_im+ROUND_UP)>>>1;
        assign dout1_re = (sub_re+ROUND_UP)>>>1;
        assign dout1_im = (sub_im+ROUND_UP)>>>1;
    end
    else begin
        assign dout0_re = $signed(add_re);
        assign dout0_im = $signed(add_im);
        assign dout1_re = $signed(sub_re);
        assign dout1_im = $signed(sub_im);
    end
endgenerate
endmodule
