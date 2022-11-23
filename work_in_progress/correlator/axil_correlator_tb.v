`default_nettype none
`include "includes.v"
`include "axil_correlator.v"

/*
*   Author: Sebastian Jorquera
*/

module axil_correlator_tb #(
    parameter DIN_WIDTH = 18,
    parameter DIN_POINT = 17,
    parameter VECTOR_LEN = 512,
    parameter MULT_DOUT = 2*DIN_WIDTH,
    parameter MULT_DELAY = 2,              //delay after the power computation
    parameter MULT_SHIFT = 0,
    parameter ACC_DIN_WIDTH = 2*DIN_WIDTH,
    parameter ACC_DIN_POINT = 2*DIN_POINT,
    parameter ACC_DOUT_WIDTH = 64,
    parameter DOUT_CAST_SHIFT = 0,
    parameter DOUT_CAST_DELAY = 0,
    parameter DOUT_WIDTH = 64,
    parameter DOUT_POINT = 2*DIN_POINT,
    parameter BRAM_DELAY = 0,
    parameter DEBUG = 0,
    //axi parameters
    parameter FPGA_DATA_WIDTH = DOUT_WIDTH,
    parameter FPGA_ADDR_WIDTH = $clog2(VECTOR_LEN),
    parameter AXI_DATA_WIDTH = 32,
    parameter DEINTERLEAVE = FPGA_DATA_WIDTH/AXI_DATA_WIDTH,
    parameter AXI_ADDR_WIDTH = FPGA_ADDR_WIDTH+$clog2(DEINTERLEAVE),
	parameter INIT_FILE = "",
    parameter RAM_TYPE="TRUE"
) (
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

    //r11 signals
    input wire [AXI_ADDR_WIDTH+1:0] s_r11_axil_awaddr,
    input wire [2:0] s_r11_axil_awprot,
    input wire s_r11_axil_awvalid,
    output wire s_r11_axil_awready,
    //write data channel
    input wire [AXI_DATA_WIDTH-1:0] s_r11_axil_wdata,
    input wire [AXI_DATA_WIDTH/8-1:0] s_r11_axil_wstrb,
    input wire s_r11_axil_wvalid,
    output wire s_r11_axil_wready,
    //write response channel 
    output wire [1:0] s_r11_axil_bresp,
    output wire s_r11_axil_bvalid,
    input wire s_r11_axil_bready,
    //read address channel
    input wire [AXI_ADDR_WIDTH+1:0] s_r11_axil_araddr,
    input wire s_r11_axil_arvalid,
    output wire s_r11_axil_arready,
    input wire [2:0] s_r11_axil_arprot,
    //read data channel
    output wire [AXI_DATA_WIDTH-1:0] s_r11_axil_rdata,
    output wire [1:0] s_r11_axil_rresp,
    output wire s_r11_axil_rvalid,
    input wire s_r11_axil_rready,

    //r22 signals
    input wire [AXI_ADDR_WIDTH+1:0] s_r22_axil_awaddr,
    input wire [2:0] s_r22_axil_awprot,
    input wire s_r22_axil_awvalid,
    output wire s_r22_axil_awready,
    //write data channel
    input wire [AXI_DATA_WIDTH-1:0] s_r22_axil_wdata,
    input wire [AXI_DATA_WIDTH/8-1:0] s_r22_axil_wstrb,
    input wire s_r22_axil_wvalid,
    output wire s_r22_axil_wready,
    //write response channel 
    output wire [1:0] s_r22_axil_bresp,
    output wire s_r22_axil_bvalid,
    input wire s_r22_axil_bready,
    //read address channel
    input wire [AXI_ADDR_WIDTH+1:0] s_r22_axil_araddr,
    input wire s_r22_axil_arvalid,
    output wire s_r22_axil_arready,
    input wire [2:0] s_r22_axil_arprot,
    //read data channel
    output wire [AXI_DATA_WIDTH-1:0] s_r22_axil_rdata,
    output wire [1:0] s_r22_axil_rresp,
    output wire s_r22_axil_rvalid,
    input wire s_r22_axil_rready,

    //r12 signals
    input wire [AXI_ADDR_WIDTH+2:0] s_r12_axil_awaddr,
    input wire [2:0] s_r12_axil_awprot,
    input wire s_r12_axil_awvalid,
    output wire s_r12_axil_awready,
    //write data channel
    input wire [AXI_DATA_WIDTH-1:0] s_r12_axil_wdata,
    input wire [AXI_DATA_WIDTH/8-1:0] s_r12_axil_wstrb,
    input wire s_r12_axil_wvalid,
    output wire s_r12_axil_wready,
    //write response channel 
    output wire [1:0] s_r12_axil_bresp,
    output wire s_r12_axil_bvalid,
    input wire s_r12_axil_bready,
    //read address channel
    input wire [AXI_ADDR_WIDTH+2:0] s_r12_axil_araddr,
    input wire s_r12_axil_arvalid,
    output wire s_r12_axil_arready,
    input wire [2:0] s_r12_axil_arprot,
    //read data channel
    output wire [AXI_DATA_WIDTH-1:0] s_r12_axil_rdata,
    output wire [1:0] s_r12_axil_rresp,
    output wire s_r12_axil_rvalid,
    input wire s_r12_axil_rready
);

axil_correlator #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .VECTOR_LEN(VECTOR_LEN),
    .MULT_DOUT(MULT_DOUT),
    .MULT_DELAY(MULT_DELAY),
    .MULT_SHIFT(MULT_SHIFT),
    .ACC_DIN_WIDTH(ACC_DIN_WIDTH),
    .ACC_DIN_POINT(ACC_DIN_POINT),
    .ACC_DOUT_WIDTH(ACC_DOUT_WIDTH),
    .DOUT_CAST_SHIFT(DOUT_CAST_SHIFT),
    .DOUT_CAST_DELAY(DOUT_CAST_DELAY),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT),
    .BRAM_DELAY(BRAM_DELAY),
    .DEBUG(DEBUG),
    .FPGA_DATA_WIDTH(FPGA_DATA_WIDTH),
    .FPGA_ADDR_WIDTH(FPGA_ADDR_WIDTH),
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .DEINTERLEAVE(DEINTERLEAVE),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .INIT_FILE(INIT_FILE),
    .RAM_TYPE(RAM_TYPE)
) axil_correaltor_inst (
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
    .s_r11_axil_awaddr(s_r11_axil_awaddr),
    .s_r11_axil_awprot(s_r11_axil_awprot),
    .s_r11_axil_awvalid(s_r11_axil_awvalid),
    .s_r11_axil_awready(s_r11_axil_awready),
    .s_r11_axil_wdata(s_r11_axil_wdata),
    .s_r11_axil_wstrb(s_r11_axil_wstrb),
    .s_r11_axil_wvalid(s_r11_axil_wvalid),
    .s_r11_axil_wready(s_r11_axil_wready),
    .s_r11_axil_bresp(s_r11_axil_bresp),
    .s_r11_axil_bvalid(s_r11_axil_bvalid),
    .s_r11_axil_bready(s_r11_axil_bready),
    .s_r11_axil_araddr(s_r11_axil_araddr),
    .s_r11_axil_arvalid(s_r11_axil_arvalid),
    .s_r11_axil_arready(s_r11_axil_arready),
    .s_r11_axil_arprot(s_r11_axil_arprot),
    .s_r11_axil_rdata(s_r11_axil_rdata),
    .s_r11_axil_rresp(s_r11_axil_rresp),
    .s_r11_axil_rvalid(s_r11_axil_rvalid),
    .s_r11_axil_rready(s_r11_axil_rready),
    .s_r22_axil_awaddr(s_r22_axil_awaddr),
    .s_r22_axil_awprot(s_r22_axil_awprot),
    .s_r22_axil_awvalid(s_r22_axil_awvalid),
    .s_r22_axil_awready(s_r22_axil_awready),
    .s_r22_axil_wdata(s_r22_axil_wdata),
    .s_r22_axil_wstrb(s_r22_axil_wstrb),
    .s_r22_axil_wvalid(s_r22_axil_wvalid),
    .s_r22_axil_wready(s_r22_axil_wready),
    .s_r22_axil_bresp(s_r22_axil_bresp),
    .s_r22_axil_bvalid(s_r22_axil_bvalid),
    .s_r22_axil_bready(s_r22_axil_bready),
    .s_r22_axil_araddr(s_r22_axil_araddr),
    .s_r22_axil_arvalid(s_r22_axil_arvalid),
    .s_r22_axil_arready(s_r22_axil_arready),
    .s_r22_axil_arprot(s_r22_axil_arprot),
    .s_r22_axil_rdata(s_r22_axil_rdata),
    .s_r22_axil_rresp(s_r22_axil_rresp),
    .s_r22_axil_rvalid(s_r22_axil_rvalid),
    .s_r22_axil_rready(s_r22_axil_rready),
    .s_r12_axil_awaddr(s_r12_axil_awaddr),
    .s_r12_axil_awprot(s_r12_axil_awprot),
    .s_r12_axil_awvalid(s_r12_axil_awvalid),
    .s_r12_axil_awready(s_r12_axil_awready),
    .s_r12_axil_wdata(s_r12_axil_wdata),
    .s_r12_axil_wstrb(s_r12_axil_wstrb),
    .s_r12_axil_wvalid(s_r12_axil_wvalid),
    .s_r12_axil_wready(s_r12_axil_wready),
    .s_r12_axil_bresp(s_r12_axil_bresp),
    .s_r12_axil_bvalid(s_r12_axil_bvalid),
    .s_r12_axil_bready(s_r12_axil_bready),
    .s_r12_axil_araddr(s_r12_axil_araddr),
    .s_r12_axil_arvalid(s_r12_axil_arvalid),
    .s_r12_axil_arready(s_r12_axil_arready),
    .s_r12_axil_arprot(s_r12_axil_arprot),
    .s_r12_axil_rdata(s_r12_axil_rdata),
    .s_r12_axil_rresp(s_r12_axil_rresp),
    .s_r12_axil_rvalid(s_r12_axil_rvalid),
    .s_r12_axil_rready(s_r12_axil_rready)
);

endmodule
