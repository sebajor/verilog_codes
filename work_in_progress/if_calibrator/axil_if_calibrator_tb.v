`default_nettype none
`include "includes.v"
`include "axil_if_calibrator.v"

module axil_if_calibrator_tb #(
    parameter DIN_WIDTH = 18,
    parameter DIN_POINT = 17,
    parameter VECTOR_LEN = 512,
    parameter COEFF_WIDTH = 32, //could be 16,32
    parameter COEFF_POINT = 20,
    parameter CAL_WIDTH = 18,
    parameter CAL_POINT = 17,
    //
    parameter CAL_BRAM_DELAY = 0,
    parameter CAL_DOUT_DELAY = 0,
    parameter CAL_DOUT_SHIFT = 0,
    //axi params for the axi cal
    parameter AXI_DATA_WIDTH = 32,
    parameter CAL_ADDR_WIDTH = $clog2(VECTOR_LEN)+$clog2(4*COEFF_WIDTH/AXI_DATA_WIDTH),

    //spectrometer parameters
    parameter POWER_DOUT = 2*CAL_WIDTH,
    parameter POWER_DELAY = 2,              //delay after the power computation
    parameter POWER_SHIFT = 0,
    parameter ACC_DIN_WIDTH = 2*CAL_WIDTH,
    parameter ACC_DIN_POINT = 2*CAL_POINT,
    parameter ACC_DOUT_WIDTH = 64,
    parameter DOUT_CAST_SHIFT = 0,
    parameter DOUT_CAST_DELAY = 0,
    parameter DOUT_WIDTH = 64,              //32,64,128
    parameter DOUT_POINT = 2*CAL_POINT,
    parameter BRAM_DELAY = 0,
    parameter DEBUG = 1,
    //axi parameters
    parameter FPGA_DATA_WIDTH = DOUT_WIDTH,
    parameter FPGA_ADDR_WIDTH = $clog2(VECTOR_LEN),
    parameter DEINTERLEAVE = FPGA_DATA_WIDTH/AXI_DATA_WIDTH,
    parameter AXI_ADDR_WIDTH = FPGA_ADDR_WIDTH+$clog2(DEINTERLEAVE),
	parameter INIT_FILE = "",
    parameter RAM_TYPE="TRUE"
)(
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din0_re, din0_im, din1_re, din1_im,
    input wire din_valid,
    input wire sync_in,
    //config signals
    input wire [31:0] acc_len,
    input wire cnt_rst,
    
    //debug
    output wire ovf_flag,
    output wire bram_ready, //sim only
    //axilite brams 
    input wire axi_clock,
    input wire axi_reset,
    //calibrator bram

    input wire [CAL_ADDR_WIDTH+1:0] s_cal_axil_awaddr,
    input wire [2:0] s_cal_axil_awprot,
    input wire s_cal_axil_awvalid,
    output wire s_cal_axil_awready,
    //write data channel
    input wire [AXI_DATA_WIDTH-1:0] s_cal_axil_wdata,
    input wire [AXI_DATA_WIDTH/8-1:0] s_cal_axil_wstrb,
    input wire s_cal_axil_wvalid,
    output wire s_cal_axil_wready,
    //write response channel 
    output wire [1:0] s_cal_axil_bresp,
    output wire s_cal_axil_bvalid,
    input wire s_cal_axil_bready,
    //read address channel
    input wire [CAL_ADDR_WIDTH+1:0] s_cal_axil_araddr,
    input wire s_cal_axil_arvalid,
    output wire s_cal_axil_arready,
    input wire [2:0] s_cal_axil_arprot,
    //read data channel
    output wire [AXI_DATA_WIDTH-1:0] s_cal_axil_rdata,
    output wire [1:0] s_cal_axil_rresp,
    output wire s_cal_axil_rvalid,
    input wire s_cal_axil_rready,

    //synth data bram
    input wire [AXI_ADDR_WIDTH+1:0] s_synth_axil_awaddr,
    input wire [2:0] s_synth_axil_awprot,
    input wire s_synth_axil_awvalid,
    output wire s_synth_axil_awready,
    //write data channel
    input wire [AXI_DATA_WIDTH-1:0] s_synth_axil_wdata,
    input wire [AXI_DATA_WIDTH/8-1:0] s_synth_axil_wstrb,
    input wire s_synth_axil_wvalid,
    output wire s_synth_axil_wready,
    //write response channel 
    output wire [1:0] s_synth_axil_bresp,
    output wire s_synth_axil_bvalid,
    input wire s_synth_axil_bready,
    //read address channel
    input wire [AXI_ADDR_WIDTH+1:0] s_synth_axil_araddr,
    input wire s_synth_axil_arvalid,
    output wire s_synth_axil_arready,
    input wire [2:0] s_synth_axil_arprot,
    //read data channel
    output wire [AXI_DATA_WIDTH-1:0] s_synth_axil_rdata,
    output wire [1:0] s_synth_axil_rresp,
    output wire s_synth_axil_rvalid,
    input wire s_synth_axil_rready
);

axil_if_calibrator #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .VECTOR_LEN(VECTOR_LEN),
    .COEFF_WIDTH(COEFF_WIDTH),
    .COEFF_POINT(COEFF_POINT),
    .CAL_WIDTH(CAL_WIDTH),
    .CAL_POINT(CAL_POINT),
    .CAL_BRAM_DELAY(CAL_BRAM_DELAY),
    .CAL_DOUT_DELAY(CAL_DOUT_DELAY),
    .CAL_DOUT_SHIFT(CAL_DOUT_SHIFT),
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .POWER_DELAY(POWER_DELAY),
    .POWER_SHIFT(POWER_SHIFT),
    .ACC_DOUT_WIDTH(ACC_DOUT_WIDTH),
    .DOUT_CAST_SHIFT(DOUT_CAST_SHIFT),
    .DOUT_CAST_DELAY(DOUT_CAST_DELAY),
    .DOUT_WIDTH(DOUT_WIDTH),
    .BRAM_DELAY(BRAM_DELAY),
    .DEBUG(DEBUG)
) axil_if_calibrator (
    .clk(clk),
    .din0_re(din0_re), 
    .din0_im(din0_im),
    .din1_re(din1_re),
    .din1_im(din1_im),
    .din_valid(din_valid),
    .sync_in(sync_in),
    .acc_len(acc_len),
    .cnt_rst(cnt_rst),
    .ovf_flag(ovf_flag),
    .bram_ready(bram_ready), //sim only
    .axi_clock(axi_clock),
    .axi_reset(axi_reset),
    .s_cal_axil_awaddr(s_cal_axil_awaddr),
    .s_cal_axil_awprot(s_cal_axil_awprot),
    .s_cal_axil_awvalid(s_cal_axil_awvalid),
    .s_cal_axil_awready(s_cal_axil_awready),
    .s_cal_axil_wdata(s_cal_axil_wdata),
    .s_cal_axil_wstrb(s_cal_axil_wstrb),
    .s_cal_axil_wvalid(s_cal_axil_wvalid),
    .s_cal_axil_wready(s_cal_axil_wready),
    .s_cal_axil_bresp(s_cal_axil_bresp),
    .s_cal_axil_bvalid(s_cal_axil_bvalid),
    .s_cal_axil_bready(s_cal_axil_bready),
    .s_cal_axil_araddr(s_cal_axil_araddr),
    .s_cal_axil_arvalid(s_cal_axil_arvalid),
    .s_cal_axil_arready(s_cal_axil_arready),
    .s_cal_axil_arprot(s_cal_axil_arprot),
    .s_cal_axil_rdata(s_cal_axil_rdata),
    .s_cal_axil_rresp(s_cal_axil_rresp),
    .s_cal_axil_rvalid(s_cal_axil_rvalid),
    .s_cal_axil_rready(s_cal_axil_rready),
    .s_synth_axil_awaddr(s_synth_axil_awaddr),
    .s_synth_axil_awprot(s_synth_axil_awprot),
    .s_synth_axil_awvalid(s_synth_axil_awvalid),
    .s_synth_axil_awready(s_synth_axil_awready),
    .s_synth_axil_wdata(s_synth_axil_wdata),
    .s_synth_axil_wstrb(s_synth_axil_wstrb),
    .s_synth_axil_wvalid(s_synth_axil_wvalid),
    .s_synth_axil_wready(s_synth_axil_wready),
    .s_synth_axil_bresp(s_synth_axil_bresp),
    .s_synth_axil_bvalid(s_synth_axil_bvalid),
    .s_synth_axil_bready(s_synth_axil_bready),
    .s_synth_axil_araddr(s_synth_axil_araddr),
    .s_synth_axil_arvalid(s_synth_axil_arvalid),
    .s_synth_axil_arready(s_synth_axil_arready),
    .s_synth_axil_arprot(s_synth_axil_arprot),
    .s_synth_axil_rdata(s_synth_axil_rdata),
    .s_synth_axil_rresp(s_synth_axil_rresp),
    .s_synth_axil_rvalid(s_synth_axil_rvalid),
    .s_synth_axil_rready(s_synth_axil_rready)
);

endmodule
