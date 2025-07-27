`default_nettype none
//`include "includes.v"

//this FFT has hardcoded din_width=16, din_point =14 and dout_widht=21


module r22sdf_correlator1024 #(
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

    //sim only signal
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



wire signed [20:0] fft0_re, fft0_im, fft1_re, fft1_im;
wire signed [1:0] fft_dout_valid;


r22sdf_fft1024 fft_inst [1:0] (
    .clk(clk),
    .rst(rst),
    .din_valid(din_valid),
    .din_re({din0, din1}),
    .din_im(0),
    .dout_re({fft0_re, fft1_re}),
    .dout_im({fft0_im, fft1_im}),
    .dout_valid(fft_dout_valid)
);

//for some reason I need to generate the sync signal..
wire signed [20:0] fft0_re_r, fft0_im_r, fft1_re_r, fft1_im_r;
delay #(
    .DATA_WIDTH(21),
    .DELAY_VALUE(1)
) delay_inst [3:0] (
    .clk(clk),
    .din({fft0_re, fft0_im, fft1_re, fft1_im}),
    .dout({fft0_re_r, fft0_im_r, fft1_re_r, fft1_im_r})
);

reg fft_dout_valid_r=0;
wire sync_in;

always@(posedge clk)
    fft_dout_valid_r <= fft_dout_valid;


assign sync_in = fft_dout_valid & ~fft_dout_valid_r;



//dout_point = 2*din_point
axil_correlator #(
    .DIN_WIDTH(21),
    .DIN_POINT(14),
    .VECTOR_LEN(1024),
    .ACC_DOUT_WIDTH(64),
    .DOUT_WIDTH(64)
) axil_correlator_inst  (
    .clk(clk),
    .din0_re(fft0_re_r),
    .din0_im(fft0_im_r),
    .din1_re(fft1_re_r),
    .din1_im(fft1_im_r),
    .din_valid(fft_dout_valid_r),
    .sync_in(sync_in),
    .acc_len(acc_len),
    .cnt_rst(rst),
    .ovf_flag(),
    .bram_ready(bram_ready),
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


