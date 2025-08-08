`default_nettype none
`include "r22sdf_bf1.v"
`include "../feedback_line/feedback_delay_line.v"
`include "../../../../dsp/delay/delay.v"
`include "../../../../xlx_templates/ram/simple_single_port/single_port_ram_read_first.v"



module r22sdf_bf1_tb #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    parameter BUFFER_SIZE = 16,
    parameter DELAY_TYPE = "RAM"    //ram or delay; ram has a 2 cycle read delay too
) (
    input wire clk, 
    input wire signed [DIN_WIDTH-1:0] din_re, din_im,
    input wire din_valid,
    input wire rst,

    output wire signed [DIN_WIDTH:0] dout_re, dout_im,
    output wire dout_valid
);

r22sdf_bf1 #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .BUFFER_SIZE(BUFFER_SIZE),
    .DELAY_TYPE(DELAY_TYPE)
) r22sfd_bf1_inst (
    .clk(clk), 
    .din_re(din_re),
    .din_im(din_im),
    .din_valid(din_valid),
    .rst(rst),
    .dout_re(dout_re),
    .dout_im(dout_im),
    .dout_valid(dout_valid)
);

reg [31:0] counter =0;
always@(posedge clk)begin
    if(din_valid)
        counter <= counter+1;
end

endmodule
