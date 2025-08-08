`default_nettype none

/*
*   Author: Sebastian Jorquera
*/

module axil_correlator #(
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


wire [DOUT_WIDTH-1:0] r11,r22;
wire signed [DOUT_WIDTH-1:0] r12_re, r12_im;
wire corr_valid;
wire [$clog2(VECTOR_LEN)-1:0]corr_addr;

correlator_lane #(
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
    .DEBUG(DEBUG)
) correlator_lane_inst (
    .clk(clk),
    .din0_re(din0_re),
    .din0_im(din0_im),
    .din1_re(din1_re),
    .din1_im(din1_im),
    .din_valid(din_valid),
    .sync_in(sync_in),
    .acc_len(acc_len),
    .cnt_rst(cnt_rst),
    .r11(r11),
    .r12_re(r12_re),
    .r12_im(r12_im),
    .r22(r22),
    .dout_valid(corr_valid),
    .dout_addr(corr_addr),
    .ovf_flag(ovf_flag)
);


wire [DOUT_WIDTH-1:0] r11_r, r22_r, r12_re_r, r12_im_r;
wire [$clog2(VECTOR_LEN)-1:0] corr_addr_r;
wire corr_valid_r;

delay #(
    .DATA_WIDTH(4*DOUT_WIDTH+$clog2(VECTOR_LEN)+1),
    .DELAY_VALUE()
) bram_delay_inst (
    .clk(clk),
    .din({r11,r22,r12_re,r12_im, corr_addr, corr_valid}),
    .dout({r11_r,r22_r,r12_re_r,r12_im_r,corr_addr_r, corr_valid_r})
);

//the memories
axil_bram_unbalanced #(
    .FPGA_DATA_WIDTH(FPGA_DATA_WIDTH),
    .FPGA_ADDR_WIDTH(FPGA_ADDR_WIDTH),
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .DEINTERLEAVE(DEINTERLEAVE),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .INIT_FILE(INIT_FILE),
    .RAM_TYPE(RAM_TYPE)
) axil_bram_r11 (
    .axi_clock(axi_clock), 
    .rst(axi_reset), 
    .s_axil_awaddr(s_r11_axil_awaddr),
    .s_axil_awprot(s_r11_axil_awprot),
    .s_axil_awvalid(s_r11_axil_awvalid),
    .s_axil_awready(s_r11_axil_awready),
    .s_axil_wdata(s_r11_axil_wdata),
    .s_axil_wstrb(s_r11_axil_wstrb),
    .s_axil_wvalid(s_r11_axil_wvalid),
    .s_axil_wready(s_r11_axil_wready),
    .s_axil_bresp(s_r11_axil_bresp),
    .s_axil_bvalid(s_r11_axil_bvalid),
    .s_axil_bready(s_r11_axil_bready),
    .s_axil_araddr(s_r11_axil_araddr),
    .s_axil_arvalid(s_r11_axil_arvalid),
    .s_axil_arready(s_r11_axil_arready),
    .s_axil_arprot(s_r11_axil_arprot),
    .s_axil_rdata(s_r11_axil_rdata),
    .s_axil_rresp(s_r11_axil_rresp),
    .s_axil_rvalid(s_r11_axil_rvalid),
    .s_axil_rready(s_r11_axil_rready),
    //fpga side
    .fpga_clk(clk),
    .bram_din(r11_r),
    .bram_addr(corr_addr_r),
    .bram_we(corr_valid_r),
    .bram_dout()
);


axil_bram_unbalanced #(
    .FPGA_DATA_WIDTH(FPGA_DATA_WIDTH),
    .FPGA_ADDR_WIDTH(FPGA_ADDR_WIDTH),
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .DEINTERLEAVE(DEINTERLEAVE),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .INIT_FILE(INIT_FILE),
    .RAM_TYPE(RAM_TYPE)
) axil_bram_r22 (
    .axi_clock(axi_clock), 
    .rst(axi_reset), 
    .s_axil_awaddr(s_r22_axil_awaddr),
    .s_axil_awprot(s_r22_axil_awprot),
    .s_axil_awvalid(s_r22_axil_awvalid),
    .s_axil_awready(s_r22_axil_awready),
    .s_axil_wdata(s_r22_axil_wdata),
    .s_axil_wstrb(s_r22_axil_wstrb),
    .s_axil_wvalid(s_r22_axil_wvalid),
    .s_axil_wready(s_r22_axil_wready),
    .s_axil_bresp(s_r22_axil_bresp),
    .s_axil_bvalid(s_r22_axil_bvalid),
    .s_axil_bready(s_r22_axil_bready),
    .s_axil_araddr(s_r22_axil_araddr),
    .s_axil_arvalid(s_r22_axil_arvalid),
    .s_axil_arready(s_r22_axil_arready),
    .s_axil_arprot(s_r22_axil_arprot),
    .s_axil_rdata(s_r22_axil_rdata),
    .s_axil_rresp(s_r22_axil_rresp),
    .s_axil_rvalid(s_r22_axil_rvalid),
    .s_axil_rready(s_r22_axil_rready),
    //fpga side
    .fpga_clk(clk),
    .bram_din(r22_r),
    .bram_addr(corr_addr_r),
    .bram_we(corr_valid_r),
    .bram_dout()
);

axil_bram_unbalanced #(
    .FPGA_DATA_WIDTH(2*FPGA_DATA_WIDTH),
    .FPGA_ADDR_WIDTH(FPGA_ADDR_WIDTH),
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .DEINTERLEAVE(2*DEINTERLEAVE),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH+1),
    .INIT_FILE(INIT_FILE),
    .RAM_TYPE(RAM_TYPE)
) axil_bram_r12 (
    .axi_clock(axi_clock), 
    .rst(axi_reset), 
    .s_axil_awaddr(s_r12_axil_awaddr),
    .s_axil_awprot(s_r12_axil_awprot),
    .s_axil_awvalid(s_r12_axil_awvalid),
    .s_axil_awready(s_r12_axil_awready),
    .s_axil_wdata(s_r12_axil_wdata),
    .s_axil_wstrb(s_r12_axil_wstrb),
    .s_axil_wvalid(s_r12_axil_wvalid),
    .s_axil_wready(s_r12_axil_wready),
    .s_axil_bresp(s_r12_axil_bresp),
    .s_axil_bvalid(s_r12_axil_bvalid),
    .s_axil_bready(s_r12_axil_bready),
    .s_axil_araddr(s_r12_axil_araddr),
    .s_axil_arvalid(s_r12_axil_arvalid),
    .s_axil_arready(s_r12_axil_arready),
    .s_axil_arprot(s_r12_axil_arprot),
    .s_axil_rdata(s_r12_axil_rdata),
    .s_axil_rresp(s_r12_axil_rresp),
    .s_axil_rvalid(s_r12_axil_rvalid),
    .s_axil_rready(s_r12_axil_rready),
    //fpga side
    .fpga_clk(clk),
    .bram_din({r12_im_r, r12_re_r}),
    .bram_addr(corr_addr_r),
    .bram_we(corr_valid_r),
    .bram_dout()
);



//debug signal
reg bram_rdy=0;
assign bram_ready = bram_rdy;
always@(posedge clk)begin
    if(corr_valid)
        bram_rdy <= 1;
    else if(s_r11_axil_rready & s_r11_axil_rvalid)
        bram_rdy <=0;
end
endmodule
