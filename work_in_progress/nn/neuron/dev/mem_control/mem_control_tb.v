`default_nettype none
`include "mem_control.v"


module mem_control_tb #(
    parameter ADDR = 256,
    parameter DOUT_WIDTH = 16,
    parameter WEIGHT_FILE = "weight_test.mem"
) (
    input clk,
    input rst,
    input valid,
    output [DOUT_WIDTH-1:0] dout,
    output dout_valid
);



mem_control #(
    .ADDR(ADDR),
    .DOUT_WIDTH(DOUT_WIDTH),
    .WEIGHT_FILE(WEIGHT_FILE)
)mem_control_inst (
    .clk(clk),
    .rst(rst),
    .valid(valid),
    .dout(dout),
    .dout_valid(dout_valid)
);

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end

endmodule 
