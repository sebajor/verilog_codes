`default_nettype none


module r22sdf_spectrometer_1024 (
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

wire signed [20.0:0] dout_re_fft0, dout_im_fft0;
wire dout_fft0_valid;

r22sdf_fft1024 r22sdf_fft1024_inst0 (
    .clk(clk),
    .rst(rst),
    .din_valid(din_valid),
    .din_re(din0_re),
    .din_im(din0_im),
    .dout_re(dout_re_fft0), 
    .dout_im(dout_im_fft0),
    .dout_valid(dout_fft0_valid)
    );

localparam FFT_WIDTH0=21;
localparam FFT_POINT0=14;

axil_spectrometer #(
    .DIN_WIDTH(21),
    .DIN_POINT(14),
    .VECTOR_LEN(1024),
    .POWER_DOUT(2*FFT_WIDTH0),
    .POWER_DELAY(2),
    .POWER_SHIFT(0),
    .ACC_DIN_WIDTH(2*FFT_WIDTH0),
    .ACC_DIN_POINT(2*FFT_POINT0),
    .DOUT_CAST_SHIFT(0),
    .DOUT_CAST_DELAY(2),
    .DOUT_WIDTH(64),
    .DOUT_POINT(2*FFT_POINT0),
    .BRAM_DELAY(2)
    ) axil_spectrometer_inst0 (
    .clk(clk),
    .din_re(dout_re_fft0),
    .din_im(dout_im_fft0),
    .din_valid(dout_fft0_valid),
    .sync_in(sync_in),
    .acc_len(acc_len),
    .cnt_rst(cnt_rst),
    .ovf_flag(),
    .bram_ready(),
    .axi_clock(axi_clock),
    .axi_reset(axi_reset),
    .s_axil_awaddr(s0_axil_awaddr),
    .s_axil_awprot(s0_axil_awprot),
    .s_axil_awvalid(s0_axil_awvalid),
    .s_axil_awready(s0_axil_awready),
    .s_axil_wdata(s0_axil_wdata),
    .s_axil_wstrb(s0_axil_wstrb),
    .s_axil_wvalid(s0_axil_wvalid),
    .s_axil_wready(s0_axil_wready),
    .s_axil_bresp(s0_axil_bresp),
    .s_axil_bvalid(s0_axil_bvalid),
    .s_axil_bready(s0_axil_bready),
    .s_axil_araddr(s0_axil_araddr),
    .s_axil_arvalid(s0_axil_arvalid),
    .s_axil_arready(s0_axil_arready),
    .s_axil_arprot(s0_axil_arprot),
    .s_axil_rdata(s0_axil_rdata),
    .s_axil_rresp(s0_axil_rresp),
    .s_axil_rvalid(s0_axil_rvalid),
    .s_axil_rready(s0_axil_rready)
);



endmodule
