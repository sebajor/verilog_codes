module axis_uart(
    parameter CLK_PER_BIT = 217,    //related to the baud rate
    parameter N_BITS = 8,
    parameter TX_SIZE=8,           //how many 8-bit symbols compose a word
    parameter RX_SIZE = 8 
)(
    input wire clk,
    input wire rst,     //high active rst
    
    input wire rx_phy,
    output wire tx_phy,

    output [N_BITS-1:0] rx_tdata,
    output              rx_tvalid,
    input               rx_tready,

    input [N_BITS-1:0]  tx_tdata,
    input               tx_valid,
    output              tx_tready
);

//rx module
wire [N_BITS-1:0] rx_din;
wire rx_val;
uart_rx #(
    .CLK_PER_BITS(CLK_PER_BIT),
    .N_BITS(N_BITS)
) uart_rx (
    .clk(clk),
    .rst(rst),
    .rx_phy(rx_phy),
    .rx_data(rx_din),
    .rx_valid(rx_val)
  );


wire rstn;
assign rstn = ~rst;
//rx fifo 


//fifo arst is negatiev edge

fifo_sync #(
    .DATA_WIDTH(N_BITS),
    .DEPTH(RX_SIZE)
) rx_fifo (
    .aclk(clk),
    .arstn(rstn),

    .in_data_tdata(rx_din),
    .in_data_tvalid(rx_val),
    .in_data_tready(),

    .out_data_tdata(rx_tdata),
    .out_data_tvalid(rx_tvalid),
    .out_data_tready(rx_tready),
    
    .full(),
    .empty()
);

//tx fifo

wire [N_BITS-1:0] tx_dout;
wire tx_valid, tx_ready;

fifo_sync #(
    .DATA_WIDTH(N_BITS),
    .DEPTH(RX_SIZE)
) tx_fifo(
    .aclk(clk),
    .arstn(rstn),

    .in_data_tdata(tx_tdata),
    .in_data_tvalid(tx_tvalid),
    .in_data_tready(tx_tready),

    .out_data_tdata(tx_dout),
    .out_data_tvalid(tx_valid),
    .out_data_tready(tx_ready),
    
    .full(),
    .empty()
);



uart_tx #( 
    .CLK_PER_BIT(CLK_PER_BIT),   //clk divider factor
    .N_BITS(N_BITS)
)(
    .axis_tdata(tx_dout),
    .axis_tvalid(tx_valid),
    .axis_tready(tx_ready), 
 
    .clk(clk),
    .tx_phy(tx_phy)
);


endmodule
