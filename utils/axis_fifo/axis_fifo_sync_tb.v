`default_nettype none
`include "rtl/sync_simple_dual_ram.v"
`include "../skid_buffer/skid_buffer.v"
`include "axis_fifo_sync.v"

module axis_fifo_sync_tb #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 4     //2**DEPTH
) (
    input wire clk,
    input wire rst,
    //write interface
    input wire [DATA_WIDTH-1:0]  write_tdata,
    input wire  write_tvalid,
    output wire write_tready,
    
    //read interface
    output wire [DATA_WIDTH-1:0] read_tdata,
    output wire read_tvalid,
    input wire  read_tready
);

axis_fifo_sync #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) axis_fifo_sync_inst (
    .clk(clk),
    .rst(rst),
    .write_tdata(write_tdata),
    .write_tvalid(write_tvalid),
    .write_tready(write_tready),
    .read_tdata(read_tdata),
    .read_tvalid(read_tvalid),
    .read_tready(read_tready)
);

endmodule
