`default_nettype none

/*
*   Like it is not advisable to ouptut directly a clock (bcs you want to keep the 
*   clock in global clock net, if you just output it can generate some routing problems)
*
*/

module output_clock (
    input wire clk,
    output wire adc_ref_clk_p, adc_ref_clk_n
);

wire adc_ref_clk;

ODDR #(
	.DDR_CLK_EDGE("OPPOSITE_EDGE"),
	.INIT (1'b0),
	.SRTYPE("SYNC")
) adc_clk_oddr (
    .Q(adc_ref_clk),
	.C(clk),
	.CE(1'b1),
	.D1(1'b1),
	.D2(1'b0),
	.R(1'b0),
	.S(1'b0)
);


OBUFDS adc_clk_obuf (
	.I(adc_ref_clk),
	.O(adc_ref_clk_p),
	.OB(adc_ref_clk_n)
);


endmodule
