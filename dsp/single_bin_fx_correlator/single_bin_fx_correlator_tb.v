`default_nettype none
`include "includes.v"
`include "single_bin_fx_correlator.v"


module single_bin_fx_correlator_tb #(
    parameter DIN_WIDTH = 14,
    parameter DIN_POINT = 13,
    parameter PARALLEL_INPUTS = 2,
    parameter TWIDD_WIDTH = 16,
    parameter TWIDD_POINT = 14,
    parameter TWIDD_FILE = "twidd_init.bin",
    parameter TWIDD_DELAY = 1,
    parameter ACC_DELAY = 0,
    parameter DFT_LEN = 1024,
    parameter DFT_DOUT_WIDTH = 32,
    parameter DFT_DOUT_POINT = 15,
    parameter DFT_DOUT_DELAY = 1,
    parameter DFT_DOUT_SHIFT = -2,
    parameter ACC_WIDTH = 32,
    parameter ACC_POINT = 15,
    parameter ACC_IN_DELAY = 1,
    parameter ACC_OUT_DELAY = 1,
    parameter DOUT_WIDTH = 32,      //the bin pt of the output is the same as the ACC
    parameter REAL_INPUT_ONLY=1,
    parameter CAST_WARNING = 0 //sim only 
) (
    input wire clk,
    input wire rst, 
    input wire signed [DIN_WIDTH-1:0] din0_re, din0_im, din1_re, din1_im,

    input wire din_valid,
    
    input wire [31:0] delay_line,   //this controls the DFT size, the one at the parameter is the max value
    input wire [31:0] acc_len,
    //
    
    output wire [DOUT_WIDTH-1:0] aa, bb, 
    output wire signed [DOUT_WIDTH-1:0] ab_re, ab_im,
    output wire dout_valid,
    output wire cast_warning,
    //axilite interface
    input wire axi_clock,
    input wire axil_rst,
    //write address channel
    input wire [$clog2(DFT_LEN)+2:0] s_axil_awaddr,
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
    input wire [$clog2(DFT_LEN)+2:0] s_axil_araddr,
    input wire s_axil_arvalid,
    output wire s_axil_arready,
    input wire [2:0] s_axil_arprot,
    //read data channel
    output wire [(2*TWIDD_WIDTH)-1:0] s_axil_rdata,
    output wire [1:0] s_axil_rresp,
    output wire s_axil_rvalid,
    input wire s_axil_rready
);


single_bin_fx_correlator #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .PARALLEL_INPUTS(PARALLEL_INPUTS),
    .TWIDD_WIDTH(TWIDD_WIDTH),
    .TWIDD_POINT(TWIDD_POINT),
    .TWIDD_FILE(TWIDD_FILE),
    .TWIDD_DELAY(TWIDD_DELAY),
    .ACC_DELAY(ACC_DELAY),
    .DFT_LEN (DFT_LEN ),
    .DFT_DOUT_WIDTH(DFT_DOUT_WIDTH),
    .DFT_DOUT_POINT(DFT_DOUT_POINT),
    .DFT_DOUT_DELAY(DFT_DOUT_DELAY),
    .DFT_DOUT_SHIFT(DFT_DOUT_SHIFT),
    .ACC_WIDTH(ACC_WIDTH),
    .ACC_POINT(ACC_POINT),
    .ACC_IN_DELAY(ACC_IN_DELAY),
    .ACC_OUT_DELAY(ACC_OUT_DELAY),
    .DOUT_WIDTH(DOUT_WIDTH),
    .REAL_INPUT_ONLY(REAL_INPUT_ONLY),
    .CAST_WARNING(CAST_WARNING)
) single_bin_fx_correlator_inst  (
    .clk(clk),
    .rst(rst), 
    .din0_re(din0_re),
    .din0_im(din0_im),
    .din1_re(din1_re),
    .din1_im(din1_im),
    .din_valid(din_valid),
    .delay_line(delay_line),   //this controls the DFT size(), the one at the parameter is the max value
    .acc_len(acc_len),
    .aa(aa),
    .bb(bb), 
    .ab_re(ab_re),
    .ab_im(ab_im),
    .dout_valid(dout_valid),
    .cast_warning(cast_warning),
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
