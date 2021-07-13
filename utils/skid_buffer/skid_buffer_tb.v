`default_nettype none
`include "skid_buffer.v"

module skid_buffer_tb #(
    parameter DIN_WIDTH = 32
) (
    input wire clk,
    input wire rst,

    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,
    output wire  din_ready,

    output wire dout_valid,
    input wire dout_ready, 
    output wire [DIN_WIDTH-1:0] dout
);


skid_buffer #(
    .DIN_WIDTH(DIN_WIDTH)
) skid_buffer_inst (
    .clk(clk),
    .rst(rst),
    .din(din),
    .din_valid(din_valid),   
    .din_ready(din_ready), 
    .dout_valid(dout_valid), 
    .dout_ready(dout_ready),
    .dout(dout)
);

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end

endmodule
