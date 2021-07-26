`default_nettype none
`include "includes.v"

/*  Take care, this module dont support full-duplex and dont handle 
collision so you need to take care to only request write or read but not both.
(I think that the zynq ps only execute read or write commands at the time, so
for that case it should work 

(this is because the axi-lite port interface with only one side of the bram
and it only handle read or write)

Also it support different word sizes, the zynq interface use 32 bits, so here
you could use 64, 128, 256 bits in the fpga side if you like.
To support 16 you need to invert the portA and portB from the unbalanced_ram

*/

module axil_bram_unbalanced #(
    parameter DATA_WIDTH_A = 64,
    parameter ADDR_WIDTH_A = 10,
    parameter WIDTH_FACTOR = 1,
	parameter INIT_FILE = "",
    //localparams
    parameter AXI_ADDR_WIDTH = (ADDR_WIDTH_A+WIDTH_FACTOR),
    parameter AXI_DATA_WIDTH = DATA_WIDTH_A>>WIDTH_FACTOR
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
    input wire [DATA_WIDTH_A-1:0] bram_din,
    input wire [ADDR_WIDTH_A-1:0] bram_addr,
    input wire bram_we,
    output wire [DATA_WIDTH_A-1:0] bram_dout
);


wire [AXI_ADDR_WIDTH-1:0] arbiter_addr;
wire arbiter_we;
wire [AXI_DATA_WIDTH-1:0] arbiter_dout, arbiter_din;

axil_bram_arbiter #(
    .DATA_WIDTH(AXI_DATA_WIDTH),
    .ADDR_WIDTH(AXI_ADDR_WIDTH)
) axil_bram_arbiter (
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
    .bram_addr(arbiter_addr),
    .bram_dout(arbiter_dout),
    .bram_din(arbiter_din),
    .bram_we(arbiter_we)
);


unbalanced_ram #(
    .DATA_WIDTH_A(DATA_WIDTH_A),
    .ADDR_WIDTH_A(ADDR_WIDTH_A),
    .WIDTH_FACTOR(WIDTH_FACTOR),
    .RAM_PERFORMANCE("LOW_LATENCY")
) ram_inst (
    .clka(fpga_clk),
    .addra(bram_addr),
    .dina(bram_din),
    .douta(bram_dout),
    .wea(bram_we),
    .ena(1'b1),
    .rsta(1'b0),
    .clkb(axi_clock),
    .addrb(arbiter_addr),
    .dinb(arbiter_din),
    .doutb(arbiter_dout),
    .web(arbiter_we),
    .enb(1'b1),
    .rstb(1'b0)
);


endmodule
