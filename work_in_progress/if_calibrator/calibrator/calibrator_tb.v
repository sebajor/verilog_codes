`default_nettype none
`include "includes.v"
`include "calibrator.v"

module calibrator_tb #(
    parameter DIN_WIDTH = 18,
    parameter DIN_POINT = 17,
    parameter VECTOR_LEN = 512,
    parameter COEFF_WIDTH = 32, //could be 16,32
    parameter COEFF_POINT = 20,
    parameter DOUT_WIDTH = 18,
    parameter DOUT_POINT = 17,
    //
    parameter BRAM_DELAY = 0,
    parameter DOUT_DELAY = 0,
    parameter DOUT_SHIFT = 0,
    parameter DEBUG = 1,
    //axi parameters
    parameter FPGA_DATA_WIDTH = 4*COEFF_WIDTH,
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

    output wire signed [DOUT_WIDTH-1:0] dout_re, dout_im,
    output wire dout_valid,
    output wire sync_out,
    //debug
    output wire ovf_flag,
    //axilite signals
    input wire axi_clock,
    input wire axi_reset,

    input wire [AXI_ADDR_WIDTH+1:0] s_axil_awaddr,
    input wire [2:0] s_axil_awprot,
    input wire s_axil_awvalid,
    output wire s_axil_awready,
    //write data channel
    input wire [AXI_DATA_WIDTH-1:0] s_axil_wdata,
    input wire [AXI_DATA_WIDTH/8-1:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output wire s_axil_wready,
    //write response channel 
    output wire [1:0] s_axil_bresp,
    output wire s_axil_bvalid,
    input wire s_axil_bready,
    //read address channel
    input wire [AXI_ADDR_WIDTH+1:0] s_axil_araddr,
    input wire s_axil_arvalid,
    output wire s_axil_arready,
    input wire [2:0] s_axil_arprot,
    //read data channel
    output wire [AXI_DATA_WIDTH-1:0] s_axil_rdata,
    output wire [1:0] s_axil_rresp,
    output wire s_axil_rvalid,
    input wire s_axil_rready
);

calibrator #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .VECTOR_LEN(VECTOR_LEN),
    .COEFF_WIDTH(COEFF_WIDTH),
    .COEFF_POINT(COEFF_POINT),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT),
    .BRAM_DELAY(BRAM_DELAY),
    .DOUT_DELAY(DOUT_DELAY),
    .DOUT_SHIFT(DOUT_SHIFT),
    .DEBUG(DEBUG),
    .FPGA_DATA_WIDTH(FPGA_DATA_WIDTH),
    .FPGA_ADDR_WIDTH(FPGA_ADDR_WIDTH),
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .DEINTERLEAVE(DEINTERLEAVE),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .INIT_FILE(INIT_FILE),
    .RAM_TYPE(RAM_TYPE)
) calibrator_inst (
    .clk(clk),
    .din0_re(din0_re),
    .din0_im(din0_im),
    .din1_re(din1_re),
    .din1_im(din1_im),
    .din_valid(din_valid),
    .sync_in(sync_in),
    .dout_re(dout_re),
    .dout_im(dout_im),
    .dout_valid(dout_valid),
    .sync_out(sync_out),
    .ovf_flag(ovf_flag),
    .axi_clock(axi_clock),
    .axi_reset(axi_reset),
    .s_axil_awaddr(s_axil_awaddr),
    .s_axil_awprot(s_axil_awprot),
    .s_axil_awvalid(s_axil_awvalid),
    .s_axil_awready(s_axil_awready),
    .s_axil_wdata(s_axil_wdata),
    .s_axil_wstrb(s_axil_wstrb),
    .s_axil_wvalid(s_axil_wvalid),
    .s_axil_wready(s_axil_wready),
    .s_axil_bresp(s_axil_bresp),
    .s_axil_bvalid(s_axil_bvalid),
    .s_axil_bready(s_axil_bready),
    .s_axil_araddr(s_axil_araddr),
    .s_axil_arvalid(s_axil_arvalid),
    .s_axil_arready(s_axil_arready),
    .s_axil_arprot(s_axil_arprot),
    .s_axil_rdata(s_axil_rdata),
    .s_axil_rresp(s_axil_rresp),
    .s_axil_rvalid(s_axil_rvalid),
    .s_axil_rready(s_axil_rready)
);

endmodule
