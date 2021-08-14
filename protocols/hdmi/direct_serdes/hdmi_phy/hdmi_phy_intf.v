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
		.OQ(dq_tmds),
		.OFB(),
		.TQ(),
		.TFB(),
		.SHIFTOUT1(),
		.SHIFTOUT2(),
		.TBYTEOUT(),		
		.CLK(pxl_clk_x5),
		.CLKDIV(pxl_clk),
		.D1(tmds_internal[10*i]),
		.D2(tmds_internal[10*i+1]),
		.D3(tmds_internal[10*i+2]),
		.D4(tmds_internal[10*i+3]),
		.D5(tmds_internal[10*i+4]),
		.D6(tmds_internal[10*i+5]),
		.D7(tmds_internal[10*i+6]),
		.D8(tmds_internal[10*i+7]),
		.TCE(1'b0),
		.OCE(1'b1),		
		.TBYTEIN(1'b0),		
		.RST(rst),	
		.SHIFTIN1(shift_out[0]),
		.SHIFTIN2(shift_out[1]),		
		.T1(0),
		.T2(0),
		.T3(0),
		.T4(0)
	);

	OSERDESE2 #(
		.DATA_RATE_OQ("DDR"),
		.DATA_RATE_TQ("SDR"),
		.DATA_WIDTH(10),
		.INIT_OQ(1'b0),
		.INIT_TQ(1'b0),
		.SERDES_MODE("SLAVE"),
		.SRVAL_OQ(1'b0),
		.SRVAL_TQ(1'b0),
		.TBYTE_CTL("FALSE"),
		.TBYTE_SRC("FALSE"),
		.TRISTATE_WIDTH(1)
	)slave_oserdes(
		.OQ(),
		.OFB(),		
		.TQ(),
		.TFB(),		
		.SHIFTOUT1(shift_out[0]),
		.SHIFTOUT2(shift_out[1]),
		.TBYTEOUT(),		
		.CLK(pxl_clk_x5),
		.CLKDIV(pxl_clk),
		.D1(1'b0),
		.D2(1'b0),
		.D3(tmds_internal[10*i+8]),
		.D4(tmds_internal[10*i+9]),
		.D5(1'b0),
		.D6(1'b0),
		.D7(1'b0),
		.D8(1'b0),
		.TCE(1'b0),
		.OCE(1'b1),
		.TBYTEIN(1'b0),
		.RST(rst),		
		.SHIFTIN1(1'b0),
		.SHIFTIN2(1'b0),
		.T1(1'b0),
		.T2(1'b0),
		.T3(1'b0),
		.T4(1'b0)
	);

	OBUFDS #(
		.IOSTANDARD("DEFAULT"),
		.SLEW("FAST")
	)OBUFDS_inst(
		.I(dq_tmds),
		.O(phy_tmds_lane[2*i+1]),
		.OB(phy_tmds_lane[2*i])
	);
end

endgenerate

wire tmds_clk_oddr;

ODDR #(
    .DDR_CLK_EDGE("OPPOSITE_EDGE"),
    .INIT(1'b0),
    .SRTYPE("SYNC")
) ODDR_inst (
    .Q(tmds_clk_oddr),
    .C(pxl_clk),
    .CE(1),
    .D1(1),
    .D2(0),
    .R(0),
    .S(0)
);

OBUFDS #(
    .IOSTANDARD("DEFAULT"),
    .SLEW("FAST")
)OBUFDS_hdmi_clk(
    .I(tmds_clk_oddr),
    .O(phy_tmds_clk[1]),
    .OB(phy_tmds_clk[0])
);


endmodule
