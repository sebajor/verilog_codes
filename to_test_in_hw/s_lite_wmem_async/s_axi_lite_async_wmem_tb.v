`default_nettype none
`include "s_axi_lite_async_wmem.v"


module s_axi_lite_async_wmem_tb #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 8,
    parameter INIT_MEM = 0,
    parameter INIT_VALS = "init.hex"
) (
    input wire S_AXI_ACLK,
    input wire S_AXI_ARESETn,
    //address write channel
    input wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input wire [2:0] S_AXI_AWPROT,
    input wire S_AXI_AWVALID,
    output wire S_AXI_AWREADY,
    //write data channel
    input wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input wire [C_S_AXI_DATA_WIDTH/8-1:0] S_AXI_WSTRB,
    input wire S_AXI_WVALID,
    output wire S_AXI_WREADY,
    //write response channel
    output wire [1:0] S_AXI_BRESP,
    output wire S_AXI_BVALID,
    input wire S_AXI_BREADY,
    //read address channel 
    input wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input wire S_AXI_ARVALID,
    output wire S_AXI_ARREADY,
    input wire [2:0] S_AXI_ARPROT,
    //read data channel
    output wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output wire [1:0] S_AXI_RRESP,
    output wire S_AXI_RVALID,
    input wire S_AXI_RREADY,

    //external signals (pl side)
    input wire rclk,
    input wire ren,
    input wire [C_S_AXI_ADDR_WIDTH-3:0] raddr, //axi drop the last 2 address bits
    output wire [C_S_AXI_DATA_WIDTH-1:0] rout,
    output wire rvalid
);





s_axi_lite_async_wmem #(
    .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
    .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
    .INIT_MEM(INIT_MEM),
    .INIT_VALS(INIT_VALS)
)s_axi_lite_async_wmem_inst (
    .S_AXI_ACLK(S_AXI_ACLK),
    .S_AXI_ARESETn(S_AXI_ARESETn),
    .S_AXI_AWADDR(S_AXI_AWADDR),
    .S_AXI_AWPROT(S_AXI_AWPROT),
    .S_AXI_AWVALID(S_AXI_AWVALID),
    .S_AXI_AWREADY(S_AXI_AWREADY),
    .S_AXI_WDATA(S_AXI_WDATA),
    .S_AXI_WSTRB(S_AXI_WSTRB),
    .S_AXI_WVALID(S_AXI_WVALID),
    .S_AXI_WREADY(S_AXI_WREADY),
    .S_AXI_BRESP(S_AXI_BRESP),
    .S_AXI_BVALID(S_AXI_BVALID),
    .S_AXI_BREADY(S_AXI_BREADY),
    .S_AXI_ARADDR(S_AXI_ARADDR),
    .S_AXI_ARVALID(S_AXI_ARVALID),
    .S_AXI_ARREADY(S_AXI_ARREADY),
    .S_AXI_ARPROT(S_AXI_ARPROT),
    .S_AXI_RDATA(S_AXI_RDATA),
    .S_AXI_RRESP(S_AXI_RRESP),
    .S_AXI_RVALID(S_AXI_RVALID),
    .S_AXI_RREADY(S_AXI_RREADY),
    .rclk(rclk),
    .ren(ren),
    .raddr(raddr),
    .rout(rout),
    .rvalid(rvalid)
);


initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end
endmodule
