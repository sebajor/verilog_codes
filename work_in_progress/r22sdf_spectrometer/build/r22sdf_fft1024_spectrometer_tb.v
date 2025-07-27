`default_nettype none

`include "includes.v"
`include "r22sdf_fft1024.v"
`include "r22sdf_fft1024_spectrometer.v"
module r22sdf_spectrometer_1024_tb (
//control signals
    input wire clk,
    input wire rst,
    input wire din_valid,
    input wire sync_in,
    input wire [31:0] acc_len,
    input wire cnt_rst,

    input wire axi_clock,
    input wire axi_reset,
    input wire signed [15:0] din0_re, din0_im,
    //axilite signals
    input wire [12.0:0] s0_axil_awaddr,
    input wire [2:0] s0_axil_awprot,
    input wire s0_axil_awvalid,
    output wire s0_axil_awready,
    //write data channel
    input wire [31:0] s0_axil_wdata,
    input wire [3:0] s0_axil_wstrb,
    input wire s0_axil_wvalid,
    output wire s0_axil_wready,
    //write response channel 
    output wire [1:0] s0_axil_bresp,
    output wire s0_axil_bvalid,
    input wire s0_axil_bready,
    //read address channel
    input wire [12.0:0] s0_axil_araddr,
    input wire s0_axil_arvalid,
    output wire s0_axil_arready,
    input wire [2:0] s0_axil_arprot,
    //read data channel
    output wire [31:0] s0_axil_rdata,
    output wire [1:0] s0_axil_rresp,
    output wire s0_axil_rvalid,
    input wire s0_axil_rready
);



localparam FFT_SIZE = 1024;
localparam DIN_WIDTH = 16;
localparam DIN_POINT = 14;
localparam DOUT_WIDHT = 64;
localparam FFTS= 1;

r22sdf_spectrometer_1024 r22sdf_spectrometer_inst (
    .clk(clk),
    .rst(rst),
    .din_valid(din_valid),
    .acc_len(acc_len),
    .axi_clock(axi_clock),
    .axi_reset(axi_reset),
    .din0_re(din0_re),
    .din0_im(din0_im),
    .s0_axil_awaddr(s0_axil_awaddr),
    .s0_axil_awprot(s0_axil_awprot),
    .s0_axil_awvalid(s0_axil_awvalid),
    .s0_axil_awready(s0_axil_awready),
    .s0_axil_wdata(s0_axil_wdata),
    .s0_axil_wstrb(s0_axil_wstrb),
    .s0_axil_wvalid(s0_axil_wvalid),
    .s0_axil_wready(s0_axil_wready),
    .s0_axil_bresp(s0_axil_bresp),
    .s0_axil_bvalid(s0_axil_bvalid),
    .s0_axil_bready(s0_axil_bready),
    .s0_axil_araddr(s0_axil_araddr),
    .s0_axil_arvalid(s0_axil_arvalid),
    .s0_axil_arready(s0_axil_arready),
    .s0_axil_arprot(s0_axil_arprot),
    .s0_axil_rdata(s0_axil_rdata),
    .s0_axil_rresp(s0_axil_rresp),
    .s0_axil_rvalid(s0_axil_rvalid),
    .s0_axil_rready(s0_axil_rready)
);

endmodule