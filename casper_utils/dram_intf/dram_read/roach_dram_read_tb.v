`default_nettype none
`include "roach_dram_read.v"

module roach_dram_read_tb #(
    parameter ADDR_WIDHT = 12
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

    //goes to any other module
    output wire [287:0] read_data,
    output wire read_valid
);

roach_dram_read #(
    .ADDR_WIDHT(ADDR_WIDHT)
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

wire [31:0] aux0 = read_data[31:0];

endmodule
