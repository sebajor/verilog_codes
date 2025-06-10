`default_nettype none
`include "../gbe_write_packetizer.v"
`include "includes.v"

module gbe_write_packetizer_tb #(
    parameter DIN_WIDTH = 128,
    parameter FIFO_DEPTH = 2048
) (
    input wire clk,
    input wire rst,
    input wire [7:0] din0,din1,din2,din3,din4,din5,din6,din7,
                     din8,din9,dinA,dinB,dinC,dinD,dinE,dinF,
    //input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,
    
    //configuration signals
    input wire [31:0] pkt_len,
    input wire [31:0] sleep_cycles,
    input wire [31:0] config_tx_dest_ip,
    input wire [31:0] config_tx_dest_port,

    //to the TGE 
    output wire [7:0] tx_data,
    output wire tx_valid,
    output wire [31:0] tx_dest_ip,
    output wire [15:0] tx_dest_port,
    output wire tx_eof,

    output wire fifo_full
);

gbe_write_packetizer #(
    .DIN_WIDTH(DIN_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
) pkt_inst (
    .clk(clk),
    .rst(rst),
    .din({dinF,dinE,dinD,dinC,dinB,dinA,din9,din8,
          din7,din6,din5,din4,din3,din2,din1,din0}
    ),
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
