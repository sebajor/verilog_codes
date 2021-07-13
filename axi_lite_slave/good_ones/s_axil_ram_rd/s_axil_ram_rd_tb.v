`default_nettype none
`include "s_axil_ram_rd.v"

module s_axil_ram_rd_tb #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 10
) (
    input wire axi_clock,
    input wire rst,
    //address read channel 
    input wire [ADDR_WIDTH+1:0] s_axil_araddr,
    input wire                  s_axil_arvalid,
    output wire                 s_axil_arready,
    input wire [2:0]            s_axil_arprot,
    //read data channel
    output wire [DATA_WIDTH-1:0] s_axil_rdata,
    output wire [1:0]            s_axil_rresp,
    output wire                  s_axil_rvalid,
    input wire                   s_axil_rready,
    //fpga interface
    input wire fpga_clk,
    input wire [ADDR_WIDTH-1:0] bram_addr,
    input wire                  we,
    input wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout,
    // to make the cocotbext-axi happy
    //address write channel
    input wire [ADDR_WIDTH-1:0] s_axil_awaddr,
    input wire [2:0] s_axil_awprot,
    input wire s_axil_awvalid,
    output wire s_axil_awready,
    //write data channel
    input wire [DATA_WIDTH-1:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output wire s_axil_wready,
    //write response channel
    output wire [1:0] s_axil_bresp,
    output wire s_axil_bvalid,
    input wire s_axil_bready
);


s_axil_ram_rd #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) ram_inst  (
    .axi_clock(axi_clock),
    .rst(rst),
    .s_axil_araddr(s_axil_araddr),
    .s_axil_arvalid(s_axil_arvalid),
    .s_axil_arready(s_axil_arready),
    .s_axil_arprot(s_axil_arprot),
    .s_axil_rdata(s_axil_rdata),
    .s_axil_rresp(s_axil_rresp),
    .s_axil_rvalid(s_axil_rvalid),
    .s_axil_rready(s_axil_rready),
    .fpga_clk(fpga_clk),
    .bram_addr(bram_addr),
    .we(we),
    .din(din),
    .dout(dout)
);

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end

endmodule
