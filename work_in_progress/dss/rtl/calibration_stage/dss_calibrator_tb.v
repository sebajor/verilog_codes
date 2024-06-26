`default_nettype none
`include "includes.v"
`include "dss_calibrator.v"

module dss_calibrator_tb #(
    parameter DIN_WIDTH = 18,
    parameter DIN_POINT = 17,
    parameter FFT_SIZE = 1024,
    parameter ACC_WIDTH = 64,
    parameter ACC_POINT = 34,
    parameter DOUT_WIDTH = 64,   //this only could be 32, 64 or 128
    parameter PRE_BRAM_LATENCY = 2,
    //localparameters
    parameter AXI_DATA_WIDTH = 32,
    parameter DEINTERLEAVE = DOUT_WIDTH/AXI_DATA_WIDTH,
    parameter AXI_ADDR_WIDTH = $clog2(FFT_SIZE)+$clog2(DEINTERLEAVE),
    parameter RAM_TYPE = "FULL"
)(
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din1_re, din1_im,din2_re, din2_im,
    input wire din_valid,
    input wire sync_in,
    input wire cnt_rst,

    //AXI-lite signals
    input wire axi_clock, 
    input wire rst, 
    
    //r11
    //write address channel
    input wire [AXI_ADDR_WIDTH+1:0] m00_axil_awaddr,
    input wire [2:0] m00_axil_awprot,
    input wire m00_axil_awvalid,
    output wire m00_axil_awready,
    //write data channel
    input wire [AXI_DATA_WIDTH-1:0] m00_axil_wdata,
    input wire [AXI_DATA_WIDTH/8-1:0] m00_axil_wstrb,
    input wire m00_axil_wvalid,
    output wire m00_axil_wready,
    //write response channel 
    output wire [1:0] m00_axil_bresp,
    output wire m00_axil_bvalid,
    input wire m00_axil_bready,
    //read address channel
    input wire [AXI_ADDR_WIDTH+1:0] m00_axil_araddr,
    input wire m00_axil_arvalid,
    output wire m00_axil_arready,
    input wire [2:0] m00_axil_arprot,
    //read data channel
    output wire [AXI_DATA_WIDTH-1:0] m00_axil_rdata,
    output wire [1:0] m00_axil_rresp,
    output wire m00_axil_rvalid,
    input wire m00_axil_rready,

    //r22
    //write address channel
    input wire [AXI_ADDR_WIDTH+1:0] m01_axil_awaddr,
    input wire [2:0] m01_axil_awprot,
    input wire m01_axil_awvalid,
    output wire m01_axil_awready,
    //write data channel
    input wire [AXI_DATA_WIDTH-1:0] m01_axil_wdata,
    input wire [AXI_DATA_WIDTH/8-1:0] m01_axil_wstrb,
    input wire m01_axil_wvalid,
    output wire m01_axil_wready,
    //write response channel 
    output wire [1:0] m01_axil_bresp,
    output wire m01_axil_bvalid,
    input wire m01_axil_bready,
    //read address channel
    input wire [AXI_ADDR_WIDTH+1:0] m01_axil_araddr,
    input wire m01_axil_arvalid,
    output wire m01_axil_arready,
    input wire [2:0] m01_axil_arprot,
    //read data channel
    output wire [AXI_DATA_WIDTH-1:0] m01_axil_rdata,
    output wire [1:0] m01_axil_rresp,
    output wire m01_axil_rvalid,
    input wire m01_axil_rready,

    //r12 real
    //write address channel
    input wire [AXI_ADDR_WIDTH+1:0] m02_axil_awaddr,
    input wire [2:0] m02_axil_awprot,
    input wire m02_axil_awvalid,
    output wire m02_axil_awready,
    //write data channel
    input wire [AXI_DATA_WIDTH-1:0] m02_axil_wdata,
    input wire [AXI_DATA_WIDTH/8-1:0] m02_axil_wstrb,
    input wire m02_axil_wvalid,
    output wire m02_axil_wready,
    //write response channel 
    output wire [1:0] m02_axil_bresp,
    output wire m02_axil_bvalid,
    input wire m02_axil_bready,
    //read address channel
    input wire [AXI_ADDR_WIDTH+1:0] m02_axil_araddr,
    input wire m02_axil_arvalid,
    output wire m02_axil_arready,
    input wire [2:0] m02_axil_arprot,
    //read data channel
    output wire [AXI_DATA_WIDTH-1:0] m02_axil_rdata,
    output wire [1:0] m02_axil_rresp,
    output wire m02_axil_rvalid,
    input wire m02_axil_rready,

    //r12 imag
    //write address channel
    input wire [AXI_ADDR_WIDTH+1:0] m03_axil_awaddr,
    input wire [2:0] m03_axil_awprot,
    input wire m03_axil_awvalid,
    output wire m03_axil_awready,
    //write data channel
    input wire [AXI_DATA_WIDTH-1:0] m03_axil_wdata,
    input wire [AXI_DATA_WIDTH/8-1:0] m03_axil_wstrb,
    input wire m03_axil_wvalid,
    output wire m03_axil_wready,
    //write response channel 
    output wire [1:0] m03_axil_bresp,
    output wire m03_axil_bvalid,
    input wire m03_axil_bready,
    //read address channel
    input wire [AXI_ADDR_WIDTH+1:0] m03_axil_araddr,
    input wire m03_axil_arvalid,
    output wire m03_axil_arready,
    input wire [2:0] m03_axil_arprot,
    //read data channel
    output wire [AXI_DATA_WIDTH-1:0] m03_axil_rdata,
    output wire [1:0] m03_axil_rresp,
    output wire m03_axil_rvalid,
    input wire m03_axil_rready
);

dss_calibrator #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .FFT_SIZE(FFT_SIZE),
    .ACC_WIDTH(ACC_WIDTH),
    .ACC_POINT(ACC_POINT),
    .DOUT_WIDTH(DOUT_WIDTH),
    .PRE_BRAM_LATENCY(PRE_BRAM_LATENCY)
) dss_calibrator_inst (
    .clk(clk),
    .din1_re(din1_re),
    .din1_im(din1_im),
    .din2_re(din2_re), 
    .din2_im(din2_im),
    .din_valid(din_valid),
    .sync_in(sync_in),
    .cnt_rst(cnt_rst),
    .axi_clock(axi_clock), 
    .rst(rst), 
    .m00_axil_awaddr(m00_axil_awaddr),
    .m00_axil_awprot(m00_axil_awprot),
    .m00_axil_awvalid(m00_axil_awvalid),
    .m00_axil_awready(m00_axil_awready),
    .m00_axil_wdata(m00_axil_wdata),
    .m00_axil_wstrb(m00_axil_wstrb),
    .m00_axil_wvalid(m00_axil_wvalid),
    .m00_axil_wready(m00_axil_wready),
    .m00_axil_bresp(m00_axil_bresp),
    .m00_axil_bvalid(m00_axil_bvalid),
    .m00_axil_bready(m00_axil_bready),
    .m00_axil_araddr(m00_axil_araddr),
    .m00_axil_arvalid(m00_axil_arvalid),
    .m00_axil_arready(m00_axil_arready),
    .m00_axil_arprot(m00_axil_arprot),
    .m00_axil_rdata(m00_axil_rdata),
    .m00_axil_rresp(m00_axil_rresp),
    .m00_axil_rvalid(m00_axil_rvalid),
    .m00_axil_rready(m00_axil_rready),
    .m01_axil_awaddr(m01_axil_awaddr),
    .m01_axil_awprot(m01_axil_awprot),
    .m01_axil_awvalid(m01_axil_awvalid),
    .m01_axil_awready(m01_axil_awready),
    .m01_axil_wdata(m01_axil_wdata),
    .m01_axil_wstrb(m01_axil_wstrb),
    .m01_axil_wvalid(m01_axil_wvalid),
    .m01_axil_wready(m01_axil_wready),
    .m01_axil_bresp(m01_axil_bresp),
    .m01_axil_bvalid(m01_axil_bvalid),
    .m01_axil_bready(m01_axil_bready),
    .m01_axil_araddr(m01_axil_araddr),
    .m01_axil_arvalid(m01_axil_arvalid),
    .m01_axil_arready(m01_axil_arready),
    .m01_axil_arprot(m01_axil_arprot),
    .m01_axil_rdata(m01_axil_rdata),
    .m01_axil_rresp(m01_axil_rresp),
    .m01_axil_rvalid(m01_axil_rvalid),
    .m01_axil_rready(m01_axil_rready),
    .m02_axil_awaddr(m02_axil_awaddr),
    .m02_axil_awprot(m02_axil_awprot),
    .m02_axil_awvalid(m02_axil_awvalid),
    .m02_axil_awready(m02_axil_awready),
    .m02_axil_wdata(m02_axil_wdata),
    .m02_axil_wstrb(m02_axil_wstrb),
    .m02_axil_wvalid(m02_axil_wvalid),
    .m02_axil_wready(m02_axil_wready),
    .m02_axil_bresp(m02_axil_bresp),
    .m02_axil_bvalid(m02_axil_bvalid),
    .m02_axil_bready(m02_axil_bready),
    .m02_axil_araddr(m02_axil_araddr),
    .m02_axil_arvalid(m02_axil_arvalid),
    .m02_axil_arready(m02_axil_arready),
    .m02_axil_arprot(m02_axil_arprot),
    .m02_axil_rdata(m02_axil_rdata),
    .m02_axil_rresp(m02_axil_rresp),
    .m02_axil_rvalid(m02_axil_rvalid),
    .m02_axil_rready(m02_axil_rready),
    .m03_axil_awaddr(m03_axil_awaddr),
    .m03_axil_awprot(m03_axil_awprot),
    .m03_axil_awvalid(m03_axil_awvalid),
    .m03_axil_awready(m03_axil_awready),
    .m03_axil_wdata(m03_axil_wdata),
    .m03_axil_wstrb(m03_axil_wstrb),
    .m03_axil_wvalid(m03_axil_wvalid),
    .m03_axil_wready(m03_axil_wready),
    .m03_axil_bresp(m03_axil_bresp),
    .m03_axil_bvalid(m03_axil_bvalid),
    .m03_axil_bready(m03_axil_bready),
    .m03_axil_araddr(m03_axil_araddr),
    .m03_axil_arvalid(m03_axil_arvalid),
    .m03_axil_arready(m03_axil_arready),
    .m03_axil_arprot(m03_axil_arprot),
    .m03_axil_rdata(m03_axil_rdata),
    .m03_axil_rresp(m03_axil_rresp),
    .m03_axil_rvalid(m03_axil_rvalid),
    .m03_axil_rready(m03_axil_rready)
);

endmodule
