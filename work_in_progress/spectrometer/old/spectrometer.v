`default_nettype none
`include "includes.v"

/*
*   Author: Sebastian Jorquera
*   This module is intended to be placed right after the FFT. It computes the 
*   power of the FFT channel and accumulate them and save them into a RAM.
*   This module supports multiple streams of FFT channels at the same time and 
*   utilize a bram per stream.
*   The brams are axi-lite capable.
*
*/


module spectrometer #(
    parameter DIN_WIDTH = 18,
    parameter DIN_POINT = 17,
    parameter PARALLEL_INPUTS = 4,
    parameter VECTOR_LEN = 512,             //this is the vector len of each stream, ie the real fft size is vector_len*parallel_inputs
    parameter POWER_DOUT = 2*DIN_WIDTH,
    parameter POWER_DELAY = 2,              //delay after the power computation
    parameter POWER_SHIFT = 0,
    parameter ACC_DIN_WIDTH = 2*DIN_WIDTH,
    parameter ACC_DIN_POINT = 2*DIN_POINT,
    parameter ACC_DOUT_WIDTH = 64,
    parameter DOUT_CAST_SHIFT = 0,
    parameter DOUT_CAST_DELAY = 0,
    parameter DOUT_WIDTH = 64,              //32,64,128
    parameter DOUT_POINT = 2*DIN_POINT,
    parameter DEBUG = 0
    //axi parameters
    parameter FPGA_DATA_WIDTH = DOUT_WIDTH,
    parameter FPGA_ADDR_WIDTH = $clog2(VECTOR_LEN),
    parameter AXI_DATA_WIDTH = 32,
    parameter DEINTERLEAVE = FPGA_DATA_WIDTH/AXI_DATA_WIDTH,
    parameter AXI_ADDR_WIDTH = FPGA_ADDR_WIDTH+$clog2(DEINTERLEAVE),
	parameter INIT_FILE = "",
    parameter RAM_TYPE="TRUE"

)(
    input wire clk,
    input wire signed [PARALLEL_INPUTS*DIN_WIDTH-1:0] din_re, din_im,
    input wire din_valid,
    input wire sync_in,
    //config signals
    input wire [31:0] acc_len,
    input wire cnt_rst

    //axilite brams (look that the signals are packed!)
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
    input wire s_axil_rready,
    



);



wire [DOUT_WIDTH*PARALLEL_INPUTS-1:0] dout;
wire [PARALLEL_INPUTS-1:0] dout_valid, ovf_warning;
wire [PARALLEL_INPUTS*$clog2(VECTOR_LEN)-1:0] bram_addr;


spectrometer_lane #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .VECTOR_LEN(VECTOR_LEN),
    .POWER_DOUT(POWER_DOUT),
    .POWER_DELAY(POWER_DELAY),
    .POWER_SHIFT(POWER_SHIFT),
    .ACC_DIN_WIDTH(ACC_DIN_WIDTH),
    .ACC_DIN_POINT(ACC_DIN_POINT),
    .ACC_DOUT_WIDTH(ACC_DOUT_WIDTH),
    .DOUT_CAST_SHIFT(DOUT_CAST_SHIFT),
    .DOUT_CAST_DELAY(DOUT_CAST_DELAY),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT),
    .DEBUG(DEBUG)
) spectrometer_lane_inst [PARALLEL_INPUTS-1:0] (
    .clk(clk),
    .din_re(din_re), 
    .din_im(din_im),
    .din_valid(din_valid),
    .sync_in(sync_in),
    .acc_len(acc_len),
    .cnt_rst(cnt_rst),
    .dout(dout),
    .dout_valid(dout_valid),
    .dout_addr(bram_addr),
    .ovf_flag(ovf_warning)
);



axil_bram_unbalanced #(
    .FPGA_DATA_WIDTH(FPGA_DATA_WIDTH),
    .FPGA_ADDR_WIDTH(FPGA_ADDR_WIDTH),
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .DEINTERLEAVE(DEINTERLEAVE),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .INIT_FILE(INIT_FILE),
    .RAM_TYPE(RAM_TYPE)
) axil_bram_inst [PARALLEL_INPUTS-1:0] (
    input wire axi_clock, 
    input wire rst, 
    //write address channel
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
    input wire s_axil_rready,

    //fpga side
    input wire fpga_clk,
    input wire [FPGA_DATA_WIDTH-1:0] bram_din,
    input wire [FPGA_ADDR_WIDTH-1:0] bram_addr,
    input wire bram_we,
    output wire [FPGA_DATA_WIDTH-1:0] bram_dout
);





endmodule