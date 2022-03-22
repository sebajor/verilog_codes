`default_nettype none
`include "i2s_pmod_v2.v"

module i2s_pmod_tb #(
    parameter CLK_FREQ = 25_000_000,
    parameter MCLK_DEC = 1,         //2**MCLK_DEC decimation factor of mclk
    parameter LRCK_DEC = 8,         //2**LRCK_DEC decimation factor of lrck
    parameter SCLK_DEC = 2          //2**SCLK_DEC decimation factor of sclk
) (
    input wire clk,
    
    //adc fpga interfaces
    //valid 0:right, 1:left
    output wire [31:0] adc_r_tdata,
    output wire [31:0] adc_l_tdata,
    output wire [1:0]  adc_tvalid,
    input  wire [1:0]  adc_tready,

    //dac fpga interfaces
    //valid 0:rigth, 1:left
    input  wire [31:0] dac_r_tdata,
    input  wire [31:0] dac_l_tdata,
    input  wire [1:0]  dac_tvalid,
    output wire [1:0]  dac_tready,

    //physical interfaces
    output wire dac_mclk,
    output wire dac_lrck,
    output wire dac_sclk,
    output wire dac_sdat,

    output wire adc_mclk,
    output wire adc_lrck,
    output wire adc_sclk,
    input  wire adc_dat 
);

i2s_pmod_v2 #(
    .CLK_FREQ(CLK_FREQ),
    .MCLK_DEC(MCLK_DEC),
    .LRCK_DEC(LRCK_DEC),
    .SCLK_DEC(SCLK_DEC)
) i2s_pmod_inst (
    .clk(clk),
    .adc_r_tdata(adc_r_tdata),
    .adc_l_tdata(adc_l_tdata),
    .adc_tvalid(adc_tvalid),
    .adc_tready(adc_tready),
    .dac_r_tdata(dac_r_tdata),
    .dac_l_tdata(dac_l_tdata),
    .dac_tvalid(dac_tvalid),
    .dac_tready(dac_tready),
    .dac_mclk(dac_mclk),
    .dac_lrck(dac_lrck),
    .dac_sclk(dac_sclk),
    .dac_sdat(dac_sdat),
    .adc_mclk(adc_mclk),
    .adc_lrck(adc_lrck),
    .adc_sclk(adc_sclk),
    .adc_dat(adc_dat)
);


endmodule

