`default_nettype none

/*
    Like we have 10bit per pxl_clk_x5 we have to cascade two OSERDESE2
*/

module hdmi_phy_intf #(
    parameter CHANNELS = 3
) (
    input wire rst,
    input wire pxl_clk,
    input wire pxl_clk_x5,  //5 times our pxl_clk 
    input wire [10*CHANNELS-1:0] tmds_internal,

    output wire [CHANNELS*2-1:0] phy_tmds_lane,
    output wire [1:0] phy_tmds_clk
);

genvar i;
generate 
for(i=0; i< CHANNELS; i=i+1) begin
    wire [1:0] shift_out;
    wire dq_tmds;
    OSERDESE2 #(
		.DATA_RATE_OQ("DDR"),
		.DATA_RATE_TQ("SDR"),
		.DATA_WIDTH	(10),
		.INIT_OQ(1'b0),
		.INIT_TQ(1'b0),
		.SERDES_MODE("MASTER"),
		.SRVAL_OQ(1'b0),
		.SRVAL_TQ(1'b0),
		.TBYTE_CTL("FALSE"),
		.TBYTE_SRC("FALSE"),
		.TRISTATE_WIDTH(1)
	)master_oserdes(
		.CLK(pxl_clk_x5),
		.CLKDIV(pxl_clk),
		.RST(rst),
		.OFB(),
		.TFB(),
		.TQ(),
		.OCE(1'b1),
		.D1(tmds_internal[10*i]),
		.D2(tmds_internal[10*i+1]),
		.D3(tmds_internal[10*i+2]),
		.D4(tmds_internal[10*i+3]),
		.D5(tmds_internal[10*i+4]),
		.D6(tmds_internal[10*i+5]),
		.D7(tmds_internal[10*i+6]),
		.D8(tmds_internal[10*i+7]),
		.OQ(dq_tmds),
		.SHIFTIN1(shift_out[0]),
		.SHIFTIN2(shift_out[1]),
		.SHIFTOUT1(),
		.SHIFTOUT2(),
		.TCE(1),
		.T1(0),
		.T2(0),
		.T3(0),
		.T4(0),
		.TBYTEIN(0),
		.TBYTEOUT()
	);

	OSERDESE2 #(
		.DATA_RATE_OQ		("DDR"),
		.DATA_RATE_TQ		("SDR"),
		.DATA_WIDTH			(10),
		.INIT_OQ			(1'b0),
		.INIT_TQ			(1'b0),
		.SERDES_MODE		("SLAVE"),
		.SRVAL_OQ			(1'b0),
		.SRVAL_TQ			(1'b0),
		.TBYTE_CTL			("FALSE"),
		.TBYTE_SRC			("FALSE"),
		.TRISTATE_WIDTH		(1)
	)slave_oserdes(
		.CLK		(ddr_bit_clock),
		.CLKDIV		(pixel_clock),
		.RST		(reset_reg),
		.OFB		(),
		.TFB		(),
		.TQ			(),
		.OCE		(1),
		.D1			(0),
		.D2			(0),
		.D3			(tmds_internal[10*i+8]),
		.D4			(tmds_internal[10*i+9]),
		.D5			(0),
		.D6			(0),
		.D7			(0),
		.D8			(0),
		.OQ			(),
		.SHIFTIN1	(0),
		.SHIFTIN2	(0),
		.SHIFTOUT1	(shift_out[0]),
		.SHIFTOUT2	(shift_out[1]),
		.TCE		(1),
		.T1			(0),
		.T2			(0),
		.T3			(0),
		.T4			(0),
		.TBYTEIN	(0),
		.TBYTEOUT	()
	);

	OBUFDS #(
		.IOSTANDARD	("DEFAULT"),
		.SLEW		("FAST")
	)OBUFDS_inst0(
		.I		(dq_tmds),
		.O		(tmds_lane[2*i+1]),
		.OB		(tmds_lane[2*i])
	);
end

endgenerate

wire tmds_clk_pre;

ODDR #(
    .DDR_CLK_EDGE("OPPOSITE_EDGE"),
    .INIT(1'b0),
    .SRTYPE("SYNC")
) ODDR_inst (
    .Q	(tmds_clk_pre),
    .C	(pxl_clk_x5),
    .CE	(1),
    .D1	(1),
    .D2	(0),
    .R	(0),
    .S	(0)
);

OBUFDS #(
    .IOSTANDARD("DEFAULT"),
    .SLEW("FAST")
)OBUFDS_hdmi_clk(
    .I		(tmds_clk_pre),
    .O		(phy_tmds_clk[1]),
    .OB		(phy_tmds_clk[0])
);


endmodule
