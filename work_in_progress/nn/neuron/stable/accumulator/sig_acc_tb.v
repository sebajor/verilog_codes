`default_nettype none
`include "sig_acc.v"
`define __SIM__

//signed accumulator

module sig_acc_tb #(
    parameter DIN_WIDTH = 16,
    parameter DIN_INT = 4,
    parameter DOUT_WIDTH = 32,
    parameter DOUT_INT = 14
) (
    input clk,
    input signed [DIN_WIDTH-1:0] din,
    input en,
    input rst, 
    input last,  //last sample
    output signed [DOUT_WIDTH-1:0] dout,
    output dout_valid
);


sig_acc #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_INT(DIN_INT),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_INT(DOUT_INT)
) sig_acc_inst (
    .clk(clk),
    .din(din),
    .en(en),
    .rst(rst), 
    .last(last),  //last sample
    .dout(dout),
    .dout_valid(dout_valid)
);

initial begin
    `ifdef __SIM__
        $dumpfile("sim.vcd");
        $dumpvars();
    `endif
end

endmodule

