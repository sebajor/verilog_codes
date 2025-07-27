`default_nettype none
`include "includes.v"
`include "r22sdf_correlator1024.v"

module r22sdf_correlator1024_tb #(
    parameter AXI_DATA_WIDTH = 32,
    parameter AXI_ADDR_WIDTH = 11
) (
    input wire clk,
    input wire rst,
    input wire din_valid, 

    input wire signed [15:0] din0, din1,
    input wire [31:0] acc_len, 
    
    //axilite signals
    input wire axi_clock,
    input wire axi_reset,
    //sim only
    output wire bram_ready,
    
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

r22sdf_correlator1024 correlator_inst (
    .clk(clk),
    .rst(rst),
    .din_valid(din_valid), 
    .din0(din0),
    .din1(din1),
    .acc_len(acc_len), 
    .axi_clock(axi_clock),
    .axi_reset(axi_reset),
    .bram_ready(bram_ready),
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
