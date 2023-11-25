`default_nettype none

/*
*   Based on the project https://github.com/SYZYGYfpga/brain-sample-hdl/tree/master/pod-adc-ltc2264/hdl
*/

ltc2268_2lanes_16bits #(
    parameter INTERNAL_CLK = 1,
    parameter ULTRASCALE = 0            //ultrascale uses iserdes3 and doesnt have bitslip
) (
    input wire main_clk,                //Clock to generate the ADC sampling clock
    //adc pins 
    input wire [1:0] adc0_p, adc0_n,    //lvds signals
    input wire [1:0] adc1_p, adc1_n,
    input wire adc_dco_p, adc_dco_n,    //
    input wire adc_fr_p, adc_fr_n,      //
    output wire adc_enc_p, adc_enc_n,   //sampling clock if internal clk
    //spi signals
    input wire adc_sdo,
    output wire adc_sdi, adc_cs_n, adc_sck,
    //output adcs signals
    output wire adc_data_clk,           //for this configuration same as enc
    output wire [13:0]  adc0_data, adc1_data,
    output wire data_valid,
    //idelay signals
    output wire idelay_ready,
    input wire idelay_ref
);
//for this mode we dont need to configure the adcs
assign adc_sdi=1, adc_cs_n=1, adc_sck=1;

//first we need to generate the output clock for the ADC
generate 
    if(INTERNAL_CLK)begin
        wire internal_clk;
        ODDR #(
            .DDR_CLK_EDGE("OPPOSITE_EDGE"),
            .INIT(0),
            .SRTYPE("SYNC")
        ) adc_enc_oddr (
            .Q(internal_clk),
            .C(main_clk),
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

//




endmodule
