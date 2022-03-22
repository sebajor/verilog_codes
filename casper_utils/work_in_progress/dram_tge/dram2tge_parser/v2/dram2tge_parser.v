`default_nettype none


module dram2tge_parser #(
    parameter DRAM_ADDR = 25
) (
    input wire clk,
    input wire en,
    input wire rst,
    
    input wire [31:0] wait_val,
    input wire [31:0] tge_pkt_size,

    //dram signals
    input wire [287:0] dram_data,
    input wire dram_valid,

    output wire [31:0] dram_addr,
    output wire read_dram
    
    //tge singals
    output wire [63:0] tge_data,
    output wire tge_valid,
    output wire tge_eof
);





endmodule
