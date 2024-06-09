`default_nettype none

/*
*   Author: Sebastian Jorquera
*   This is a simple bram meant to be write by axilite. Since sometimes we want
*   to write some custom size values this code search for the closest 32-multiple 
*   and the resize it to the wanted size.
*/

module axil_bram_custom_size #(
    parameter FPGA_DATA_WIDTH = 64,
    parameter FPGA_ADDR_WIDTH = 10,
    parameter AXI_DATA_WIDTH = 32,
    parameter FPGA_SIGNED = 1,
	parameter INIT_FILE = "",
    parameter RAM_TYPE="TRUE",
    parameter CAST = 0,          //CAST=0 means that we just drop the unnecesary bits and 
                                //its the programmer who has to write the good values
                                //in terms of latency this is better
                                //parameters to calculate the size of the ports
    parameter FACTOR = FPGA_DATA_WIDTH/AXI_DATA_WIDTH,
    parameter MOD = FPGA_DATA_WIDTH%(AXI_DATA_WIDTH*FACTOR),
    parameter BRAM_DATA_SIZE = (MOD==0)? (FACTOR*AXI_DATA_WIDTH) : ((FACTOR+1)*AXI_DATA_WIDTH),
    parameter DEINTERLEAVE = BRAM_DATA_WIDTH/AXI_DATA_WIDTH,
    parameter AXI_ADDR_WIDTH = FPGA_ADDR_WIDTH+$clog2(DEINTERLEAVE)

) (
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

if(FPGA_SIGNED)
    wire signed [BRAM_DATA_SIZE-1:0] bram_din_internal = $signed(bram_din); //to extend the sign
else
    wire [BRAM_DATA_SIZE-1:0] bram_din_internal = bram_din;

wire [BRAM_DATA_SIZE-1:0] bram_dout_internal;


axil_bram_unbalanced #(
    .FPGA_DATA_WIDTH(BRAM_DATA_SIZE),
    .FPGA_ADDR_WIDTH(FPGA_ADDR_WIDTH),
    .AXI_DATA_WIDTH(AXI_ADDR_WIDTH),
	.INIT_FILE(INIT_FILE)
) axil_bram_unbalanced_inst (
    .axi_clock(axi_clock), 
    .rst(rst), 
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
    .s_axil_rready(s_axil_rready),
    .fpga_clk(fpga_clk),
    .bram_din(bram_din_internal),
    .bram_addr(bram_addr),
    .bram_we(bram_we),
    .bram_dout(bram_dout_internal)
);

generate 
    if(CAST)begin
        if(FPGA_SIGNED)begin
            assign bram_dout = $signed(bram_dout_internal);
        end
        else begin
            assign bram_dout = bram_dout_internal;
        end
    end
    else 
        assign bram_dout = bram_dout_internal[FPGA_DATA_WIDTH-1:0];
endgenerate

endmodule
