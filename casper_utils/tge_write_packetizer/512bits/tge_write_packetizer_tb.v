`default_nettype none
`include "../tge_write_packetizer.v"
`include "includes.v"

module tge_write_packetizer_tb #(
    parameter DIN_WIDTH = 512,
    parameter FIFO_DEPTH = 512
) (
    input wire clk,
    input wire rst,
    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,
    
    //configuration signals
    input wire [31:0] pkt_len,
    input wire [31:0] sleep_cycles,
    input wire [31:0] config_tx_dest_ip,
    input wire [31:0] config_tx_dest_port,

    //to the TGE 
    output wire [63:0] tx_data,
    output wire tx_valid,
    output wire [31:0] tx_dest_ip,
    output wire [15:0] tx_dest_port,
    output wire tx_eof,

    output wire fifo_full
);

wire [31:0] din0 = din[31:0];
wire [31:0] din1 = din[32+:32];
wire [31:0] din2 = din[64+:32];
wire [31:0] din3 = din[96+:32];
wire [31:0] din4 = din[128+:32];
wire [31:0] din5 = din[160+:32];
wire [31:0] din6 = din[192+:32];
wire [31:0] din7 = din[224+:32];

wire [31:0] din8 = din[32*8+:32];
wire [31:0] din9 = din[32*9+:32];
wire [31:0] dinA = din[32*10+:32];
wire [31:0] dinB = din[32*11+:32];
wire [31:0] dinC = din[32*12+:32];
wire [31:0] dinD = din[32*13+:32];
wire [31:0] dinE = din[32*14+:32];
wire [31:0] dinF = din[32*15+:32];

tge_write_packetizer #(
    .DIN_WIDTH(DIN_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
) pkt_inst (
    .clk(clk),
    .rst(rst),
    .din(din),
    .din_valid(din_valid),
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

wire [31:0] tx0 = tx_data[31:0];
wire [31:0] tx1 = tx_data[63:32];

reg [31:0] counter=0;
always@(posedge clk)begin
    if(tx_valid)begin
        if(counter==(pkt_len-1))
            counter <=0;
        else
            counter <= counter+1;
    end
end


endmodule