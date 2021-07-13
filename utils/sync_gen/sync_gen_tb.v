`default_nettype none
`include "sync_gen.v"

module sync_gen_tb (
    input wire clk,
    input wire ce,
    input wire rst,
    input wire [31:0] sync_period,
    
    input wire sync_in,
    output wire sync_out,
    input wire [31:0] val
);

sync_gen sync_gen_inst (
    .clk(clk),
    .ce(ce),
    .rst(rst),
    .sync_period(sync_period),
    .sync_in(sync_in),
    .sync_out(sync_out)
);

reg [31:0] val_r=0;
always@(posedge clk)
    val_r <= val;

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end


endmodule
