`default_nettype none

module data_phy #(
    parameter ARCH = "7-series"
)
 ( 
    input wire sync_rst, 

    input wire [1:0] adc_data_p, adc_data_n,    //data in two lane mode
    //these signals came from the clock_alignment module
    input wire data_clk_bufio,
    input wire data_clk_div,
    input wire bitslip,

    output wire [15:0] adc_data
);

wire [1:0] ibufds_data;
    
IBUFDS #(
    .DIFF_TERM ("TRUE"),
    .IOSTANDARD ("LVDS_25")
    ) adc_ibufds [1:0] (
    .I(adc_data_p),
    .IB(adc_data_n),
    .O(ibufds_data)
);

wire [1:0] data_delayed;

IDELAYE2 #(
	.IDELAY_TYPE("FIXED"),
	.DELAY_SRC("IDATAIN"),
	.IDELAY_VALUE(14), // a value of 14 should give ~1.1ns with a 200MHz reference
	.HIGH_PERFORMANCE_MODE ("TRUE"),
	.SIGNAL_PATTERN("DATA"),
	.REFCLK_FREQUENCY(200),
	.CINVCTRL_SEL("FALSE"),
	.PIPE_SEL("FALSE")
) adc_data_idelay [1:0] (
	.C(1'b0),
	.REGRST(1'b0),
	.LD(1'b0),
	.CE(1'b0),
	.INC(1'b0),
	.CINVCTRL(1'b0),
	.CNTVALUEIN({2{9'b0}}),
	.IDATAIN(ibufds_data),
	.DATAIN(1'b0),
	.LDPIPEEN(1'b0),
	.DATAOUT(data_delayed),
	.CNTVALUEOUT()
);



ISERDESE2 #(
	.DATA_RATE("DDR"),
	.DATA_WIDTH(8),
	.INTERFACE_TYPE("NETWORKING"), // Using internal clock network routing
	.DYN_CLKDIV_INV_EN("FALSE"), // We do not need dynamic clocking
	.DYN_CLK_INV_EN("FALSE"), // We do not need dynamic clocking
	.NUM_CE(1), // Only use CE1 as a clock enable
	.OFB_USED("FALSE"), // Only used for connection with OSERDESE2
	.IOBDELAY("BOTH"),
	.SERDES_MODE("MASTER")
) adc_serdes0 (
	.Q1(adc_data[1]),
	.Q2(adc_data[3]),
	.Q3(adc_data[5]),
	.Q4(adc_data[7]),
	.Q5(adc_data[9]),
	.Q6(adc_data[11]),
	.Q7(adc_data[13]),
	.Q8(adc_data[15]),
	.O(),
	.SHIFTOUT1(),
	.SHIFTOUT2(),
	.D(1'b0),
	.DDLY(data_delayed[0]),
	.CLK(data_clk_bufio),
	.CLKB(~data_clk_bufio),
	.CE1(1'b1),
	.CE2(1'b0),
	.RST(sync_rst),
	.CLKDIV(data_clk_div),
	.CLKDIVP(1'b0),
	.OCLK(1'b0),
	.OCLKB(1'b0),
	.BITSLIP(bitslip),
	.SHIFTIN1(1'b0),
	.SHIFTIN2(1'b0),
	.OFB(1'b0),
	.DYNCLKDIVSEL(1'b0),
	.DYNCLKSEL(1'b0)
);


ISERDESE2 #(
	.DATA_RATE("DDR"),
	.DATA_WIDTH(8),
	.INTERFACE_TYPE("NETWORKING"), // Using internal clock network routing
	.DYN_CLKDIV_INV_EN("FALSE"), // We do not need dynamic clocking
	.DYN_CLK_INV_EN("FALSE"), // We do not need dynamic clocking
	.NUM_CE(1), // Only use CE1 as a clock enable
	.OFB_USED("FALSE"), // Only used for connection with OSERDESE2
	.IOBDELAY("BOTH"),
	.SERDES_MODE("MASTER")
) adc_serdes1 (
	.Q1(adc_data[0]),
	.Q2(adc_data[2]),
	.Q3(adc_data[4]),
	.Q4(adc_data[6]),
	.Q5(adc_data[8]),
	.Q6(adc_data[10]),
	.Q7(adc_data[12]),
	.Q8(adc_data[14]),
	.O(),
	.SHIFTOUT1(),
	.SHIFTOUT2(),
	.D(1'b0),
	.DDLY(data_delayed[1]),
	.CLK(data_clk_bufio),
	.CLKB(~data_clk_bufio),
	.CE1(1'b1),
	.CE2(1'b0),
	.RST(sync_rst),
	.CLKDIV(data_clk_div),
	.CLKDIVP(1'b0),
	.OCLK(1'b0),
	.OCLKB(1'b0),
	.BITSLIP(bitslip),
	.SHIFTIN1(1'b0),
	.SHIFTIN2(1'b0),
	.OFB(1'b0),
	.DYNCLKDIVSEL(1'b0),
	.DYNCLKSEL(1'b0)
);


endmodule
