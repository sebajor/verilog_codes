`default_nettype none
`include "includes.v"
`include "../feedback_line.v"

/*
*   Author: Sebastian Jorquera
*/

module r22sdf_bf1 #(
    parameter DIN_WIDTH = 16,
    parameter FEEDBACK_SIZE = 8,
    parameter DELAY_TYPE = "delay", //delay or bram
    parameter MULT_LATENCY = 0
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din_re, din_im,
    input wire din_valid,
    input wire control,
    output reg signed [DIN_WIDTH:0] dout_re, dout_im,
    output wire dout_valid
);

reg signed [DIN_WIDTH:0] feedback_din_re=0, feedback_din_im=0;
wire signed [DIN_WIDTH:0] feedback_dout_re, feedback_dout_im;



always@(posedge clk)begin
    if(control)begin
        feedback_din_re <= din_re;
        feedback_din_im <= din_im;
        dout_re <= feedback_dout_re;
        dout_im <= feedback_dout_im;
    end
    else begin
        feedback_din_re <= $signed(din_re)-$signed(feedback_dout_re);
        feedback_din_im <= $signed(din_im)-$signed(feedback_dout_im);
        dout_re <= $signed(feedback_dout_re)+$signed(din_re);
        dout_im <= $signed(feedback_dout_im)+$signed(din_im);

    end
end


feedback_line #(
    .DIN_WIDTH(2*(DIN_WIDTH+1)),
    .FEEDBACK_SIZE(FEEDBACK_SIZE-1),    //one latency since (CHECK)
    .DELAY_TYPE(DELAY_TYPE)
) feedback_line_inst (
    .clk(clk),
    .din({feedback_din_re, feedback_din_im}),
    .dout({feedback_dout_re, feedback_dout_im})
);



endmodule
