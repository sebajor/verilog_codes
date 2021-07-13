`default_nettype none
`include "piso.v"

/* DIN --> FIFO -->time multiplex -->DOUT
*/

module piso_tb #(
    parameter DIN_WIDTH = 256,
    parameter DOUT_WIDTH = 64,
    parameter FIFO_DEPTH = 512

) (
    input wire clk,
    input wire rst,

    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,
    
    output wire [DOUT_WIDTH-1:0] dout,
    output wire dout_valid,
    input wire dout_ready
);

piso #(
    .DIN_WIDTH(DIN_WIDTH),
    .DOUT_WIDTH(DOUT_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)

) piso_inst (
    .clk(clk),
    .rst(rst),
    .din(din),
    .din_valid(din_valid),
    .dout(dout),
    .dout_valid(dout_valid),
    .dout_ready(dout_ready)
);


initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end
endmodule 
