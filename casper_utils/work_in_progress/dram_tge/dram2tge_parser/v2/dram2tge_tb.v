`default_nettype none
`include "dram2tge.v"

module dram2tge_tb #( 
    parameter DRAM_ADDR = 12
)(
    input wire clk,
    input wire rst,
    input wire en,
    input wire [31:0] tge_wait, tge_pkt, tge_total_pkts,
    input wire [31:0] dram0,dram1,dram2,dram3,dram4,dram5,
    input wire [31:0] dram6,dram7,dram8,
    input wire dram_valid,

    output wire [31:0] dram_addr,
    output wire dram_request,
    output wire [31:0] tge0,tge1,
    output wire tge_data_valid,
    output wire tge_eof,
    output wire finish
);

dram2tge #(
    .DRAM_ADDR(DRAM_ADDR)
)dram2tge (
    .clk(clk),
    .rst(rst),
    .en(en),
    .tge_wait(tge_wait),
    .tge_pkt(tge_pkt), 
    .tge_total_pkts(tge_total_pkts),
    .dram_request(dram_request),
    .dram_addr(dram_addr),
    .dram_data({dram8,dram7,dram6,dram5,dram4,dram3,dram2,dram1,dram0}),
    .dram_valid(dram_valid),
    .tge_data({tge1,tge0}),
    .tge_data_valid(tge_data_valid),
    .tge_eof(tge_eof),
    .finish(finish)
);


endmodule
