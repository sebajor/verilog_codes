`default_nettype none
`include "axil_bram_unbalanced.v"

module axil_bram_unbalanced_tb #(
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


axil_bram_unbalanced #(
    .DATA_WIDTH_A(DATA_WIDTH_A),
    .ADDR_WIDTH_A(ADDR_WIDTH_A),
    .WIDTH_FACTOR(WIDTH_FACTOR)
) axil_bram_inst(
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
    .bram_din(bram_din),
    .bram_addr(bram_addr),
    .bram_we(bram_we),
    .bram_dout(bram_dout)
);

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end

endmodule
