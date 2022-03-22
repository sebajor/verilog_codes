`default_nettype none
`include "../roach_dram_write.v"

module roach_dram_write_tb #(
    parameter DIN_WIDTH = 96,    //should divide perfectly 288
    parameter DRAM_ADDR = 25,
    //stupid ise dont allow $clog2 in localparam :(
    parameter CYCLES = 288/DIN_WIDTH,
    parameter CYCLES_CLOG = $clog2(CYCLES)
) (
    input wire clk,
    input wire rst,
    input wire en_write,

    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,

    //to the DRAM module
    output wire dram_rst, 
    output wire [DRAM_ADDR-1:0] dram_addr,   //check!
    //output wire [287:0] dram_data,
    output wire [31:0] dout0,dout1,dout2,dout3,dout4,dout5,dout6,dout7,dout8,

    output wire [35:0] wr_be,       //byte enable
    output wire rwn,                //1:read, 0:write
    output wire [31:0] cmd_tag,
    output wire cmd_valid
);

roach_dram_write #(
    .DIN_WIDTH(DIN_WIDTH),
    .DRAM_ADDR(DRAM_ADDR)
) roach_dram_write_inst (
    .clk(clk),
    .rst(rst),
    .en_write(en_write),
    .din(din),
    .din_valid(din_valid),
    .dram_rst(dram_rst), 
    .dram_addr(dram_addr),   //check!
    .dram_data({dout8,dout7,dout6,dout5,dout4,dout3,dout2,dout1,dout0}),
    .wr_be(wr_be),       //byte enable
    .rwn(rwn),                //1:read, 0:write
    .cmd_tag(cmd_tag),
    .cmd_valid(cmd_valid)
);


endmodule
