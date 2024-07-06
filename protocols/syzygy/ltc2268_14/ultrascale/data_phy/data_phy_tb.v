`default_nettype none
`include "../../primitives.v"
`include "data_phy.v"
`include "bitslip_shift.v"


module data_phy_tb (
    input wire sync_rst,
    input wire adc_data_p0, adc_data_p1,
    //these signals came from the clock alignment module
    input wire data_clk_bufio,
    input wire data_clk_div,
    input wire [3:0] bitslip_count,

    output wire [15:0] adc_data,
    output wire [7:0] iserdes0_dout, iserdes1_dout
);

wire adc_data_n0 = ~adc_data_p0;
wire adc_data_n1 = ~adc_data_p1;

reg [15:0] debug =0;
reg [3:0] counter=7;
always@(posedge data_clk_bufio or negedge data_clk_bufio)begin
    debug[2*counter] <= adc_data_p0;
    debug[2*counter+1] <= adc_data_p1;
    if(counter==0)
        counter <= 7;
    else
        counter<=counter-1;
end

data_phy data_phy_inst (
    .sync_rst(sync_rst),
    .adc_data_p({adc_data_p1, adc_data_p0}), 
    .adc_data_n({adc_data_n1, adc_data_n0}),
    .data_clk_bufio(data_clk_bufio),
    .data_clk_div(data_clk_div),
    .bitslip_count(bitslip_count),
    .adc_data(adc_data),
    .iserdes0_dout(iserdes0_dout),
    .iserdes1_dout(iserdes1_dout)
);

endmodule
