`default_nettype none
`include "dsp48_macc.v"


module dsp48_macc_tb #(
    parameter DIN1_WIDTH = 16,
    parameter DIN2_WIDTH = 16,
    parameter DOUT_WIDTH = 48
)(
    input wire clk,
    input wire new_acc,
    input wire signed [DIN1_WIDTH-1:0] din1,
    input wire signed [DIN2_WIDTH-1:0] din2,
    input wire din_valid,
    output wire signed [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);



dsp48_macc #(
    .DIN1_WIDTH(DIN1_WIDTH),
    .DIN2_WIDTH(DIN2_WIDTH),
    .DOUT_WIDTH(DOUT_WIDTH)
) dsp48_macc_inst (
    .clk(clk),
    .new_acc(new_acc),
    .din1(din1),
    .din2(din2),
    .din_valid(din_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end

endmodule
