`default_nettype none
`include "includes.v"
`include "axil_msdft_correlator.v"


module axil_msdft_correlator_tb #(
    //msdft parameters
    parameter DIN_WIDTH = 14,//8,
    parameter DIN_POINT = 13,//7,
    parameter TWIDD_WIDTH = 16, //this is limited by the axi intf... check how to change it
    parameter TWIDD_POINT = 14,
    parameter TWIDD_FILE = "twidd_init.hex",
    parameter DFT_LEN = 8192,
    parameter MSDFT_WIDTH = 32,
    parameter MSDFT_POINT = 16,
    //accumulator parameters
    parameter ACC_WIDTH = 32,   //acumulator input (after the correlation mults)   
    parameter ACC_POINT = 12,
    parameter DOUT_WIDTH = 32
) (

    input wire clk, 
    input wire rst,
    input wire signed [DIN_WIDTH-1:0] din1_re, din1_im, din2_re, din2_im,
    input wire din_valid,

    output wire signed [DOUT_WIDTH-1:0] r12_re, r12_im,
    output wire [DOUT_WIDTH-1:0] r11, r22,
    output wire dout_valid,

    //delay line configuration
    input wire [31:0] delay_line,
    input wire [31:0] acc_len,

    //axil signals
    input wire axi_clock,
    input wire axil_rst,
    //write address channel
    input wire [$clog2(DFT_LEN)+1:0] s_axil_awaddr,
    input wire [2:0] s_axil_awprot,
    input wire s_axil_awvalid,
    output wire s_axil_awready,
    //write data channel
    input wire [2*TWIDD_WIDTH-1:0] s_axil_wdata,
    input wire [(2*TWIDD_WIDTH)/8-1:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output wire s_axil_wready,
    //write response channel
    output wire [1:0] s_axil_bresp,
    output wire s_axil_bvalid,
    input wire s_axil_bready,
    //read address channel
    input wire [$clog2(DFT_LEN)+1:0] s_axil_araddr,
    input wire s_axil_arvalid,
    output wire s_axil_arready,
    input wire [2:0] s_axil_arprot,
    //read data channel
    output wire [(2*TWIDD_WIDTH)-1:0] s_axil_rdata,
    output wire [1:0] s_axil_rresp,
    output wire s_axil_rvalid,
    input wire s_axil_rready
);

axil_msdft_correlator #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .TWIDD_WIDTH(TWIDD_WIDTH),
    .TWIDD_POINT(TWIDD_POINT),
    .TWIDD_FILE(TWIDD_FILE),
    .DFT_LEN(DFT_LEN),
    .MSDFT_WIDTH(MSDFT_WIDTH),
    .MSDFT_POINT(MSDFT_POINT),
    .ACC_WIDTH(ACC_WIDTH),
    .ACC_POINT(ACC_POINT),
    .DOUT_WIDTH(DOUT_WIDTH)
)axil_msdft_correlator_inst (
    .clk(clk), 
    .rst(rst),
    .din1_re(din1_re),
    .din1_im(din1_im),
    .din2_re(din2_re),
    .din2_im(din2_im),
    .din_valid(din_valid),
    .r12_re(r12_re),
    .r12_im(r12_im),
    .r11(r11),
    .r22(r22),
    .dout_valid(dout_valid),
    .delay_line(delay_line),
    .acc_len(acc_len),
    .axi_clock(axi_clock),
    .axil_rst(axil_rst),
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
