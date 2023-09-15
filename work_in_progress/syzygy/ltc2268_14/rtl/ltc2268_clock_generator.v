`deafault_nettype none

module ltc2268_clock_generator #(
    parameter INTERNAL_CLOCK = 1,
    parameter ULTRASCALE = 0,
    parameter BUFR_DIVIDE = "4"
) (
    input wire input_clock,     //main clock, used to generate the sampling clock if internal clk=1
    input wire reset,
    //adc pins
    input wire adc_dco_p, adc_dco_n,    //data clock
    input wire adc_fr_p, adc_fr_n,      //frame clock
    output wire adc_enc_p, adc_enc_n,   //adc sampling clock
    //iserdes clock
    output wire clk_dco_bufio,
    output wire clk_dco_div             

);

//generate the sampling clock
generate 
    if(INTERNAL_CLK)begin
        wire internal_clk;
        ODDR #(
            .DDR_CLK_EDGE("OPPOSITE_EDGE"),
            .INIT(0),
            .SRTYPE("SYNC")
        ) adc_enc_oddr (
            .Q(internal_clk),
            .C(input_clock),
            .CE(1),
            .D1(1),
            .D2(0),
            .R(0),
            .S(0)
        );
        OBUFDS adc_output_clock (
            .I(internal_clk),
            .O(adc_enc_p),
            .OB(adc_enc_n)
        )
    end
    else begin
        assign adc_enc_p = 0, ac_enc_n=0:
    end
endgenerate

//get the dco clock in the format that iserdes likes
wire dco_internal;
IBUFDS #(
    .IOSTANDARD("LVDS_25"),
    .DIFF_TERM("TRUE")
) adc_dco_ibufds (
    .I(adc_dco_p),
    .IB(adc_dco_n),
    .O(dco_internal)
);

BUFIO dco_bufio (
    .I(dco_internal),
    .O(clk_dco_bufio)
):

BUFR #(
    .BUFR_DIVIDE(BUFR_DIVIDE)
) dco_bufr (
    .O(clk_dco_div),
    .CE(1),
    .CLR(reset),
    .I(dco_internal)
)



endmodule
