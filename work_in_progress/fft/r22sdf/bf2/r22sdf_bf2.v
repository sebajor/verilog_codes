`default_nettype none

/*
*   author: Sebastian Jorquera
*/

module r22sdf_bf2 #(
    parameter DIN_WIDTH = 16,
    parameter FEEDBACK_SIZE = 8,
    parameter DELAY_TYPE = "delay",  //delay or bram
    parameter SCALE = 1,
    parameter ROUND_UP=1

) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din_re, din_im,
    input wire [1:0] control,
    output wire signed [DIN_WIDTH:0] dout_re, dout_im
);

wire signed [DIN_WIDTH-1:0] delay_re, delay_im;
//control[0] controls the ouput 
//control[1] controls the multiplication by -j (mux re and im part)
reg signed [DIN_WIDTH:0] dout_re_r=0, dout_im_r=0;
reg signed [DIN_WIDTH-1:0] feedback_din_re, feedback_din_im;


//to understand the control signals look at the diagram, where the signals that controls the
//swap of the real, imag are controlled by a negated input of the control[1] with and AND of control[1]

always@(*)begin
    case(control)
        2'b00, 2'b10: begin
            dout_re_r = delay_re;
            dout_im_r = delay_im;
            feedback_din_re = din_re;
            feedback_din_im = din_im;
        end
        2'b01:begin
            //this means that the din real part and img part are swapped and the sum/sub operations are changed
            dout_re_r = delay_re+din_im;
            dout_im_r = delay_im-din_re;
            feedback_din_re = delay_re-din_im;
            feedback_din_im = delay_im+din_re;
        end
        2'b11:begin
            //this means that the din real and img part are not swap
            dout_re_r = delay_re+din_re;
            dout_im_r = delay_im+din_re;
            feedback_din_re = delay_re-din_re;
            feedback_din_im = delay_im-din_im;
        end
    endcase
end

assign dout_re = dout_re_r;
assign dout_im = dout_im_r;


feedback_line #(
    .DIN_WIDTH(2*DIN_WIDTH),
    .FEEDBACK_SIZE(FEEDBACK_SIZE),
    .DELAY_TYPE(DELAY_TYPE)
) feedback_inst (
    .clk(clk),
    .din({feedback_din_re, feedback_din_im}),
    .dout({delay_re, delay_im})
);


endmodule
