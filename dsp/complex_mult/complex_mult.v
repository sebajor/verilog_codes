`default_nettype none 

/*
*   Author: Sebastian Jorquera
*   
*   Takes 6 cycles
*/

module complex_mult #(
    parameter DIN1_WIDTH = 16,
    parameter DIN2_WIDTH = 16
) (
    input wire clk,
    
    input wire [DIN1_WIDTH-1:0] din1_re, din1_im,
    input wire [DIN2_WIDTH-1:0] din2_re, din2_im,
    input wire din_valid,

    output wire [DIN1_WIDTH+DIN2_WIDTH:0] dout_re, dout_im,
    output wire dout_valid
);

//duplicate the data
reg [DIN1_WIDTH-1:0] din1_re_a=0, din1_re_b=0, din1_im_a=0, din1_im_b=0;
reg [DIN2_WIDTH-1:0] din2_re_a=0, din2_re_b=0, din2_im_a=0, din2_im_b=0;

reg valid_a=0, valid_b=0;

always@(posedge clk)begin
    valid_a <= din_valid;
    valid_b <= din_valid;
    din1_re_a <= din1_re;
    din1_re_b <= din1_re;
    din1_im_a <= din1_im;
    din1_im_b <= din1_im;
    din2_re_a <= din2_re;
    din2_re_b <= din2_re;
    din2_im_a <= din2_im;
    din2_im_b <= din2_im;
end

//mult_a = din1_re*din2_re;
//mult_b = din1_re*din2_im
//mult_c = din1_im*din2_im;
//mult_d = din1_im*din2_re;

wire [DIN1_WIDTH+DIN2_WIDTH-1:0] mult_a, mult_b, mult_c, mult_d;
wire mult_valid;

dsp48_mult #(
    .DIN1_WIDTH(DIN1_WIDTH),
    .DIN2_WIDTH(DIN2_WIDTH),
    .DOUT_WIDTH(DIN1_WIDTH+DIN2_WIDTH)
) mult_re_re (
    .clk(clk),
    .rst(),
    .din1(din1_re_a),
    .din2(din2_re_a),
    .din_valid(valid_a),
    .dout(mult_a),
    .dout_valid(mult_valid)
);


dsp48_mult #(
    .DIN1_WIDTH(DIN1_WIDTH),
    .DIN2_WIDTH(DIN2_WIDTH),
    .DOUT_WIDTH(DIN1_WIDTH+DIN2_WIDTH)
) mult_re_im (
    .clk(clk),
    .rst(),
    .din1(din1_re_b),
    .din2(din2_im_b),
    .din_valid(valid_a),
    .dout(mult_b),
    .dout_valid()
);


dsp48_mult #(
    .DIN1_WIDTH(DIN1_WIDTH),
    .DIN2_WIDTH(DIN2_WIDTH),
    .DOUT_WIDTH(DIN1_WIDTH+DIN2_WIDTH)
) mult_im_im (
    .clk(clk),
    .rst(),
    .din1(din1_im_a),
    .din2(din2_im_a),
    .din_valid(valid_b),
    .dout(mult_c),
    .dout_valid()
);

dsp48_mult #(
    .DIN1_WIDTH(DIN1_WIDTH),
    .DIN2_WIDTH(DIN2_WIDTH),
    .DOUT_WIDTH(DIN1_WIDTH+DIN2_WIDTH)
) mult_im_re (
    .clk(clk),
    .rst(),
    .din1(din1_im_b),
    .din2(din2_re_b),
    .din_valid(valid_b),
    .dout(mult_d),
    .dout_valid()
);

//add the complex result
//mult_re = mult_a-mult_c
//mult_im = mult_b+mult_d
reg [DIN1_WIDTH+DIN2_WIDTH:0] mult_re=0, mult_im=0;
reg dout_valid_r =0;
always@(posedge clk)begin
    if(mult_valid)begin
        dout_valid_r <= 1;
        mult_re <= $signed(mult_a)-$signed(mult_c);
        mult_im <= $signed(mult_b)+$signed(mult_d);
    end
    else
        dout_valid_r<= 0;
end

assign dout_re = mult_re;
assign dout_im = mult_im;
assign dout_valid = dout_valid_r;


endmodule
