`default_nettype none
`include "word_detection.v"

/* get instruction from uart and get the address and word to read/write
write: mwr addr[31:0] word[31:0];
read:  mrd addr[31:0]
*/


module parse_instruction #(
    parameter UART_BIT = 8,
    parameter AXI_ADDR = 4,    //bytes
    parameter AXI_WORD = 4    //bytes 

)(
    input wire clk,
    //uart signal

    input wire [UART_BIT-1:0] uart_in,
    input wire uart_valid,

    //outputs
    output wire mwr_valid,
    output wire [8*AXI_ADDR-1:0] mwr_address,
    output wire [8*AXI_WORD-1:0] mwr_data,
    input wire mwr_tready,

    output wire mrd_valid,
    output wire [8*AXI_ADDR-1:0] mrd_address,
    input wire mrd_tready
);



wire [8*(AXI_ADDR+AXI_WORD)-1:0] mwr_info;
assign {mwr_address, mwr_data} = mwr_info;

word_detection #(
    .UART_BIT(UART_BIT),
    .PATTERN_SIZE(3),
    .PATTERN("mwr"),
    .INFO_SIZE((AXI_ADDR+AXI_WORD)) //bytes    
) mwr_detection (
    .clk(clk),
    .uart_in(uart_in),
    .uart_valid(uart_valid),

    .dout_tdata(mwr_info),
    .dout_tvalid(mwr_valid),
    .dout_tready(mwr_tready)
);


word_detection #(
    .UART_BIT(UART_BIT),
    .PATTERN_SIZE(3),
    .PATTERN("mrd"),
    .INFO_SIZE(AXI_ADDR) //bytes    
) mrd_detection (
    .clk(clk),
    .uart_in(uart_in),
    .uart_valid(uart_valid),

    .dout_tdata(mrd_address),
    .dout_tvalid(mrd_valid),
    .dout_tready(mrd_tready)
);

endmodule

