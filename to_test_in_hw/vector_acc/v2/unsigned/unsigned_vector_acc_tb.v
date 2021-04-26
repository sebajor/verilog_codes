`default_nettype none
`include "unsigned_vector_acc.v"

module unsigned_vector_acc_tb #(
    parameter DIN_WIDTH = 16,
    parameter VECTOR_LEN = 64,
    parameter DOUT_WIDTH = 32
) (
    input wire clk,
    input wire new_acc,

    input wire signed [DIN_WIDTH-1:0] din,
    input wire din_valid,

    output wire signed [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);


unsigned_vector_acc #(
    .DIN_WIDTH(DIN_WIDTH),
    .VECTOR_LEN(VECTOR_LEN),
    .DOUT_WIDTH(DOUT_WIDTH)
) signed_vector_acc_inst (
    .clk(clk),
    .new_acc(new_acc),
    .din(din),
    .din_valid(din_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end

endmodule
