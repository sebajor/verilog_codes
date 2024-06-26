`default_nettype none
`include "includes.v"
`include "tge_write_packetizer.v"
`include "pkt_gen.v"


module pkt_gen_tb #(
    parameter DIN_WIDTH = 32,
    parameter PARALLEL = 4,
    parameter FIFO_DEPTH = 512
) (
    input wire clk,
    input wire en,
    input wire rst,
    //pkt gen
    input wire [31:0] burst_len,
    input wire [31:0] sleep_write,

    //tge
    input wire [31:0] sleep_cycles,
    input wire [31:0] pkt_len,

    output wire [63:0] dout,
    output wire dout_valid,
    output wire dout_eof
);

wire [DIN_WIDTH*PARALLEL-1:0] din;
wire din_valid;


tge_write_packetizer #(
    .DIN_WIDTH(DIN_WIDTH*PARALLEL),
    .FIFO_DEPTH(FIFO_DEPTH)
) packetizer (
    .clk(clk),
    .rst(rst),
    .din(din),
    .din_valid(din_valid),
    .pkt_len(pkt_len),
    .sleep_cycles(sleep_cycles),
    .config_tx_dest_ip(),
    .config_tx_dest_port(),
    .tx_data(dout),
    .tx_valid(dout_valid),
    .tx_dest_ip(),
    .tx_dest_port(),
    .tx_eof(dout_eof)
);

wire [31:0] dout0 = dout[31:0];
wire [31:0] dout1 = dout[63:32];
reg [31:0] debug_counter =0;
always@(posedge clk)begin
    if(dout_valid)
        debug_counter <= debug_counter+1;
end

pkt_gen #(
    .DOUT_WIDTH(DIN_WIDTH),
    .PARALLEL(PARALLEL)
) pkt_gen_inst (
    .clk(clk),
    .en(en),
    .rst(rst),
    .burst_len(burst_len),
    .sleep_write(sleep_write),
    .dout(din),
    .dout_valid(din_valid)
);



endmodule
