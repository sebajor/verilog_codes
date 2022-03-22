`default_nettype none
`include "dram_tge.v"

module dram_tge_tb #(
    parameter FIFO_DEPTH = 8,
    parameter BUBBLE = 20
) (
    input wire clk,
    input wire rst,
    input wire en,
    input wire [31:0] dram_burst_size,  //must take in account the fifo size!
    input wire [31:0] tge_pkt_size,     //
    input wire [31:0] wait_pkt,         //cycles to wait between packets 
    input wire [24:0] dram_count_init,  //the init address of read
    input wire [31:0] dram0, dram1,dram2,dram3,dram4,dram5,dram6,
    input wire [31:0] dram7, dram8,
    input wire dram_valid,
    output wire dram_request,
    output wire [31:0] dram_addr,
    input wire dram_ready,    //~empty
    output wire [31:0] tge0,tge1,tge2,tge3,tge4,tge5,tge6,tge7,
    output wire tge_data_valid,
    output wire tge_eof,

    output wire finish
);


dram_tge #(
    .FIFO_DEPTH(FIFO_DEPTH),
    .BUBBLE(BUBBLE)
) dram_tge_inst (
    .clk(clk),
    .rst(rst),
    .en(en),
    .dram_burst_size(dram_burst_size),
    .tge_pkt_size(tge_pkt_size),   
    .wait_pkt(wait_pkt),       
    .dram_count_init(dram_count_init),
    .dram_data({dram8,dram7,dram6,dram5,dram4,dram3,dram2,dram1,dram0}),
    .dram_valid(dram_valid),
    .dram_request(dram_request),
    .dram_addr(dram_addr),
    .dram_ready(dram_ready),
    .tge_data({tge7,tge6,tge5,tge4,tge3,tge2,tge1,tge0}),
    .tge_data_valid(tge_data_valid),
    .tge_eof(tge_eof),
    .finish(finish)
);


endmodule
