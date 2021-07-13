`default_nettype none

/* By construction the steer vector is centrosymmetric, uesprit takes advantage
of that multiplying by [ I jI; PI -jPI]  where I is de identity and PI is the 
exchage matrix.. The idea is to have a real correlation matrix so we avoid
complex operations.
so we have: y1  = Q^{H} x1  
            y2          x2 
*/

module centrosym_matrix #(
    parameter DIN_WIDTH = 18
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din1_re, din1_im,
    input wire signed [DIN_WIDTH-1:0] din2_re, din2_im,
    input wire din_valid,

    output wire signed [DIN_WIDTH:0] y1_re, y1_im,
    output wire signed [DIN_WIDTH:0] y2_re, y2_im,
    output wire dout_valid
);

//pipelined to improve timing 
reg [DIN_WIDTH-1:0] din1_re_r=0, din1_im_r=0;
reg [DIN_WIDTH-1:0] din2_re_r=0, din2_im_r=0;
reg din_valid_r=0;

always@(posedge clk)begin
    din1_re_r <= din1_re;   din1_im_r <= din1_im;
    din2_re_r <= din2_re;   din2_im_r <= din2_im;
    din_valid_r <= din_valid;
end


reg signed [DIN_WIDTH:0] up_re=0, up_im=0, down_re=0, down_im=0;
reg dout_valid_r=0;
always@(posedge clk)begin
    up_re <= $signed(din1_re_r)+$signed(din2_re_r);
    up_im <= $signed(din1_im_r)+$signed(din2_im_r);

    down_re <= $signed(din1_im_r)-$signed(din2_im_r);
    down_im <= $signed(din2_re_r)-$signed(din1_re_r);
    dout_valid_r <= din_valid_r;
end

assign y1_re = up_re;
assign y1_im = up_im;
assign y2_re = down_re;
assign y2_im = down_im;
assign dout_valid = dout_valid_r;

endmodule
