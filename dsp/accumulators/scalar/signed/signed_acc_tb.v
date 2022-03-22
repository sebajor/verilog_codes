`default_nettype none
`include "signed_acc.v"

module signed_acc_tb #(
    parameter DIN_WIDTH = 16,
    parameter ACC_WIDTH = 32
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din,
    input wire din_valid,
    input wire acc_done,

    output wire signed [ACC_WIDTH-1:0] dout,
    output wire dout_valid
);


signed_acc #(
    .DIN_WIDTH(DIN_WIDTH),
    .ACC_WIDTH(ACC_WIDTH)
)signed_acc_inst (
    .clk(clk),
    .din(din),
    .din_valid(din_valid),
    .acc_done(acc_done),
    .dout(dout),
    .dout_valid(dout_valid)
);

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end
endmodule 

