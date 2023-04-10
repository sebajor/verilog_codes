`default_nettype none

module tge_write_packetizer_tb #(
    parameter DIN_WIDTH = 128,
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
