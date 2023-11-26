`default_nettype none

/*
*   Note that the adc adds two zeros in bits 0 and 1
*/

module data_phy (
    input wire sync_rst,

    input wire [1:0] adc_data_p, adc_data_n,//data in two lane mode
    //these signals came from the clock alignment module
    input wire data_clk_bufio,
    input wire data_clk_div,
    input wire [3:0] bitslip_count,

    output wire [15:0] adc_data,
    //debuging signals
    output wire [7:0] iserdes0_dout, iserdes1_dout
);


wire [1:0] ibufds_data;
    
IBUFDS #(
    .DIFF_TERM ("TRUE"),
    .IOSTANDARD ("LVDS")
    ) adc_ibufds [1:0] (
    .I(adc_data_p),
    .IB(adc_data_n),
    .O(ibufds_data)
);

wire [7:0] serdes0_dout, serdes1_dout;


ISERDESE3 #(
      .DATA_WIDTH(8),                 // Parallel data width (4,8)
      .FIFO_ENABLE("FALSE"),          // Enables the use of the FIFO
      .FIFO_SYNC_MODE("FALSE"),       // Always set to FALSE. TRUE is reserved for later use.
      .IS_CLK_B_INVERTED(1'b1),       // Optional inversion for CLK_B. 1 = internal inversion
      .IS_CLK_INVERTED(1'b0),         // Optional inversion for CLK
      .IS_RST_INVERTED(1'b0),         // Optional inversion for RST
      .SIM_DEVICE("ULTRASCALE_PLUS")  // Set the device version for simulation functionality (ULTRASCALE,
                                      // ULTRASCALE_PLUS, ULTRASCALE_PLUS_ES1, ULTRASCALE_PLUS_ES2)
   )
   adc_serdes0 (
      .FIFO_EMPTY(),            // 1-bit output: FIFO empty flag
      .INTERNAL_DIVCLK(),       // 1-bit output: Internally divided down clock used when FIFO is
                                // disabled (do not connect)
      .Q(serdes0_dout),           // 8-bit registered output
      .CLK(data_clk_bufio),      // 1-bit input: High-speed clock
      .CLKDIV(data_clk_div),    // 1-bit input: Divided Clock
      .CLK_B(data_clk_bufio),    // 1-bit input: Inversion of High-speed clock CLK
      .D(ibufds_data[0]),         // 1-bit input: Serial Data Input
      .FIFO_RD_CLK(),           // 1-bit input: FIFO read clock
      .FIFO_RD_EN(),            // 1-bit input: Enables reading the FIFO when asserted
      .RST(sync_rst)               // 1-bit input: Asynchronous Reset
   );


ISERDESE3 #(
      .DATA_WIDTH(8),                 // Parallel data width (4,8)
      .FIFO_ENABLE("FALSE"),          // Enables the use of the FIFO
      .FIFO_SYNC_MODE("FALSE"),       // Always set to FALSE. TRUE is reserved for later use.
      .IS_CLK_B_INVERTED(1'b1),       // Optional inversion for CLK_B. 1 = internal inversion
      .IS_CLK_INVERTED(1'b0),         // Optional inversion for CLK
      .IS_RST_INVERTED(1'b0),         // Optional inversion for RST
      .SIM_DEVICE("ULTRASCALE_PLUS")  // Set the device version for simulation functionality (ULTRASCALE,
                                      // ULTRASCALE_PLUS, ULTRASCALE_PLUS_ES1, ULTRASCALE_PLUS_ES2)
   ) adc_serdes1 (
      .FIFO_EMPTY(),            // 1-bit output: FIFO empty flag
      .INTERNAL_DIVCLK(),       // 1-bit output: Internally divided down clock used when FIFO is
                                // disabled (do not connect)
      .Q(serdes1_dout),           // 8-bit registered output
      .CLK(data_clk_bufio),      // 1-bit input: High-speed clock
      .CLKDIV(data_clk_div),    // 1-bit input: Divided Clock
      .CLK_B(data_clk_bufio),    // 1-bit input: Inversion of High-speed clock CLK
      .D(ibufds_data[1]),         // 1-bit input: Serial Data Input
      .FIFO_RD_CLK(),           // 1-bit input: FIFO read clock
      .FIFO_RD_EN(),            // 1-bit input: Enables reading the FIFO when asserted
      .RST(sync_rst)               // 1-bit input: Asynchronous Reset
   );

//shift serdes dout by the bitslip

bitslip_shift #(
    .DIN_WIDTH(8)
)bitslip_shift_inst0  (
    .clk(data_clk_div),
    .din(serdes0_dout),
    .rst(sync_rst), 
    .bitslip_count(bitslip_count),
    .dout({adc_data[1], adc_data[3], adc_data[5], adc_data[7],
           adc_data[9], adc_data[11], adc_data[13], adc_data[15]})
);


bitslip_shift #(
    .DIN_WIDTH(8)
)bitslip_shift_inst1  (
    .clk(data_clk_div),
    .din(serdes1_dout),
    .rst(sync_rst), 
    .bitslip_count(bitslip_count),
    .dout({adc_data[0], adc_data[2], adc_data[4], adc_data[6],
           adc_data[8], adc_data[10], adc_data[12], adc_data[14]})
);


assign iserdes0_dout = serdes0_dout;
assign iserdes1_dout = serdes1_dout;


endmodule
