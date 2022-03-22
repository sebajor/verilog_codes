`default_nettype none

/*
    dram read interface connected to the ethernet transmiter
*/

module r_dram_one_gbe #(
    parameter DRAM_ADDR = 25,
    parameter FIFO_DEPTH = 512
) (
    input wire clk,
    input wire rst,

    input wire read_en,
    input wire [31:0] burst_len,    //32 words is the minimum recommended
    input wire next_burst,          //rising edge starts a reading of burst_len
    input wire repeat_burst,        
    output wire burst_done,
    output wire finish,

    //goes to input dram
    output wire [ADDR_WIDHT-1:0] dram_addr,
    output wire rwn, 
    output wire cmd_valid,

    //goes to output dram
    input wire rd_ack,  //dont care
    input wire cmd_ack, //dont care
    input wire [287:0] dram_data,
    input wire rd_tag,  //dont care
    input wire rd_valid,

    //1gbe config signals
    input wire [31:0] pkt_len,
    input wire [31:0] sleep_cycles,
    input wire [31:0] config_tx_dest_ip,
    input wire [31:0] config_tx_dest_port,

    //to the one gbe 
    output wire [7:0] tx_data,
    output wire tx_valid,
    output wire [31:0] tx_dest_ip,
    output wire [15:0] tx_dest_port,
    output wire tx_eof,
    output wire fifo_full
);

wire [287:0] read_data;
wire read_data_valid;

roach_dram_read #(
    .ADDR_WIDHT(DRAM_ADDR)
) roach_dram_read_inst (
    .clk(clk),
    .rst(rst),
    .read_en(read_en),
    .burst_len(burst_len),
    .next_burst(next_burst),
    .repeat_burst(repeat_burst),        
    .burst_done(burst_done),
    .finish(finish),
    .dram_addr(dram_addr),
    .rwn(rwn), 
    .cmd_valid(cmd_valid),
    .rd_ack(rd_ack),
    .cmd_ack(cmd_ack),
    .dram_data(dram_data),
    .rd_tag(rd_tag),
    .rd_valid(rd_valid),
    .read_data(read_data),
    .read_valid(read_valid)
);


gbe_write_packetizer #(
    DIN_WIDTH(288),
    FIFO_DEPTH(512)
) gbe_write_packet_inst (
    .clk(clk),
    .rst(rst),
    .din(read_data),
    .din_valid(read_data_valid),
    .pkt_len(pkt_len),
    .sleep_cycles(sleep_cycles),
    .config_tx_dest_ip(config_tx_dest_ip),
    .config_tx_dest_port(config_tx_dest_port),
    .tx_data(tx_data),
    .tx_valid(tx_valid),
    .tx_dest_ip(tx_dest_ip),
    .tx_dest_port(tx_dest_port),
    .tx_eof(tx_eof),
    .fifo_full(fifo_full)

);

endmodule
