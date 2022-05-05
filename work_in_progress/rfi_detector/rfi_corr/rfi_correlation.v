`default_nettype none

module rfi_correlation #(
    parameter DIN_WIDTH = 18,
    parameter DIN_POINT = 17,
    //
    parameter POST_MULT_DELAY = 0,

) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] sig_re, sig_im, ref_re, ref_im,
    input wire din_valid,
    input wire sync_in,



);


wire ref_im_conj = ~ref_im+1'b1;
wire signed [2*DIN_WIDTH:0] cmult_re, cmult_im;
wire cmult_valid;

//6 cycles of delay
complex_mult #(
    .DIN1_WIDTH(DIN_WIDTH),
    .DIN2_WIDTH(DIN_WIDTH)
)complex_mult_inst (
    .clk(clk),
    .din1_re(sig_re),
    .din1_im(sig_im),
    .din2_re(ref_re),
    .din2_im(ref_im_conj),
    .din_valid(din_valid),
    .dout_re(cmult_re),
    .dout_im(cmult_im),
    .dout_valid(cmult_valid)
);

wire sync_delay;
delay #(
    .DATA_WIDTH(1),
    .DELAY_VALUE(6)
) cmult_delay (
    .clk(clk),
    .din(sync_in),
    .dout(sync_delay)
);

//delay the cmult output
wire signed [2*DIN_WIDTH:0] data_re, data_im;
wire data_valid, sync_data;
delay #(
    .DATA_WIDTH(2*(2*DIN_WIDTH+1)+2),
    .DELAY_VALUE(6)
) cmult_delay (
    .clk(clk),
    .din({cmult_re,cmult_im, cmult_valid,sync_delay}),
    .dout({data_re, data_im, data_valid, sync_data})
);

//acc control


//

signed_vacc #(
    DIN_WIDTH = 32,
    VECTOR_LEN = 64,
    DOUT_WIDTH = 64
) (
    clk,
    new_acc,
    din,
    din_valid,
    dout,
    dout_valid
);

endmodule
