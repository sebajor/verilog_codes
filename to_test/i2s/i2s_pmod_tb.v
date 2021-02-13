`default_nettype none
`include "i2s_pmod.v"

module i2s_pmod_tb #(
    parameter MCLK_FREQ = 25_000_000,
    parameter DIVIDER_FACTOR = 9    //2**divide factor
)(
    input wire clk,

    output wire [63:0] adc_tdata, //[63:32] left, [31:0] rigth
    output wire adc_tvalid,

    //left and right chanels 
    input wire [63:0] dac_tdata,
    input wire dac_tvalid,
    output wire dac_tready,

    //physical interfaces
    output wire dac_mclk,
    output wire dac_lrck,
    output wire dac_sclk, //i think is not required
    output wire dac_sdat,

    output wire adc_mclk,
    output wire adc_lrck,
    output wire adc_sclk,
    input  wire adc_dat,
    //tb signals
    output wire [31:0] dac_tb

);

i2s_pmod #(
    .MCLK_FREQ(25_000_000),
    .DIVIDER_FACTOR(9)    //2**divide factor
) i2s_pmod_inst (
    .clk(clk),

    .adc_tdata(adc_tdata), //[63:32] left(), [31:0] rigth
    .adc_tvalid(adc_tvalid),

    //left and right chanels 
    .dac_tdata(dac_tdata),
    .dac_tvalid(dac_tvalid),
    .dac_tready(dac_tready),

    //physical interfaces
    .dac_mclk(dac_mclk),
    .dac_lrck(dac_lrck),
    .dac_sclk(dac_sclk), //i think is not required
    .dac_sdat(dac_sdat),

    .adc_mclk(adc_mclk),
    .adc_lrck(adc_lrck),
    .adc_sclk(adc_sclk),
    .adc_dat(adc_dat)
);

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end

reg [31:0] dac_tb_r=0;
reg [4:0] counter=0;
reg sclk_dly=0;
always@(posedge clk)begin
    sclk_dly <= dac_sclk;
end

always@(posedge clk)begin
    if(~sclk_dly&& dac_sclk)begin
        counter <= counter+1;
        dac_tb_r[counter] <= dac_sdat;
    end
end

assign dac_tb = dac_tb_r;





endmodule
