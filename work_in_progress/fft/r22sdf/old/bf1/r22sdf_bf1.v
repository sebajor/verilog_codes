`default_nettype none

/*
*   author: Sebastian Jorquera
*/

module r22sdf_bf1 #(
    parameter DIN_WIDTH = 16,
    parameter FEEDBACK_SIZE = 8,
    parameter DELAY_TYPE = "delay",  //delay or bram
    parameter ROUND_UP = 1,
    parameter SCALE = 1

) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din_re, din_im,
    input wire control,
    output wire signed [DIN_WIDTH:0] dout_re, dout_im
);

wire signed [DIN_WIDTH-1:0] delay_re, delay_im;
reg signed [DIN_WIDTH-1:0] feedback_din_re=0, feedback_din_im=0;
reg signed [DIN_WIDTH:0] dout_re_r=0, dout_im_r=0;

//compute butterfly operations

always@(*)begin
    case(control)
        0:begin
            feedback_din_re = din_re;
            feedback_din_im = din_im;
            dout_re_r = delay_re;
            dout_im_r = delay_im;
        end
        1:begin
            feedback_din_re = $signed(din_re)-$signed(delay_re);
            feedback_din_im = $signed(din_im)-$signed(delay_im);
            dout_re_r = $signed(delay_re)+$signed(din_re);
            dout_im_r = $signed(delay_im)+$signed(din_im);
        end
    endcase
end

assign dout_re = dout_re_r;
assign dout_im = dout_im_r;


feedback_line #(
    .DIN_WIDTH(2*DIN_WIDTH),
    .FEEDBACK_SIZE(FEEDBACK_SIZE),
    .DELAY_TYPE(DELAY_TYPE)
) feedback_line_inst (
    .clk(clk),
    .din({feedback_din_re, feedback_din_im}),
    .dout({delay_re, delay_im})
);


endmodule
