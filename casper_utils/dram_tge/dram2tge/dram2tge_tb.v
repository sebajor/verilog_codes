`default_nettype none
`include "dram2tge.v"

module dram2tge_tb 
(
    input wire clk,
    input wire rst,
    input wire en,
    input wire [31:0] dram0,dram1,dram2,dram3,dram4,dram5,
    input wire [31:0] dram6,dram7,dram8,
    input wire dram_valid,
    output wire dram_request,
    input wire dram_ready,
    output wire [31:0] tge0,tge1,tge2,tge3,tge4,tge5,tge6,tge7,
    output wire tge_data_valid
);


dram2tge dramtge_inst (
    .clk(clk),
    .rst(rst),
    .en(en),
    .dram_data({dram8,dram7,dram6,dram5,dram4,dram3,dram2,dram1,dram0}),
    .dram_valid(dram_valid),
    .dram_request(dram_request),
    .dram_ready(dram_ready),
    .tge_data({tge7,tge6,tge5,tge4,tge3,tge2,tge1,tge0}),
    .tge_data_valid(tge_data_valid)
);


endmodule
