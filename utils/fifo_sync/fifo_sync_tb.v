`default_nettype none
`include "rtl/sync_simple_dual_ram.v"
`include "fifo_sync.v"

module fifo_sync_tb #(
    parameter DIN_WIDTH = 16,
    parameter FIFO_DEPTH = 3
) (
    input wire clk,
    input wire rst,
    
    input wire [DIN_WIDTH-1:0] wdata,
    input wire w_valid,

    output wire empty, full,
    output wire [DIN_WIDTH-1:0] rdata,
    output wire r_valid,
    input wire read_req
);



fifo_sync #(
    .DIN_WIDTH(DIN_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
) fifo_sync_inst (
    .clk(clk),
    .rst(rst),
    .wdata(wdata),
    .w_valid(w_valid),
    .empty(empty),
    .full(full),
    .rdata(rdata),
    .r_valid(r_valid),
    .read_req(read_req)
);


endmodule
