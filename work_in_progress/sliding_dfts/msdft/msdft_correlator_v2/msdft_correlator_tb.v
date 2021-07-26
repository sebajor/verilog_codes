`default_nettype none
`include "msdft_correlator.v"

/*
    recommended parameters:
        msdft_width = din_width+clog2(DFT_LEN)
        msdft_point = din_point
        //acc_width and acc_pt must satisfy
        //acc_int = 2*msdft_int = 2*(msdft_width-msdft_pt)
        //ex:
        acc_point = din_point
        acc_width = 2*msdft_width-din_point
        dout_int = acc_int+clog2(MAX_ACC_LEN)
*/

module msdft_correlator_tb #(
    parameter DIN_WIDTH = 8,
    parameter DIN_POINT = 7,
    parameter TWIDD_WIDTH = 16,
    parameter TWIDD_POINT = 14,
    parameter TWIDD_FILE = "twidd_init.hex",
    parameter DFT_LEN = 128,
    parameter MSDFT_WIDTH = 16, //msdft output width
    parameter MSDFT_POINT = 7,  
    parameter ACC_WIDTH = 25,   //accumulator input (after the correlation multiplications)
    parameter ACC_POINT = 7,
    parameter DOUT_WIDTH = 32   //output of the accumulator
) (
    input wire clk, 
    input wire rst,
    input wire signed [DIN_WIDTH-1:0] din1_re, din1_im,
    input wire signed [DIN_WIDTH-1:0] din2_re, din2_im,
    input wire din_valid,
    output wire signed [DOUT_WIDTH-1:0] r12_re, r12_im,
    output wire [DOUT_WIDTH-1:0] r11, r22,
    output wire dout_valid,
    //configurations signals
    input wire [31:0] delay_line,   //to modify the dft_len
    input wire [31:0] acc_len,      //accumulation lenght
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

msdft_correlator #(
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
) msdft_correlator_inst (
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

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end


endmodule
