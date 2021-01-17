`timescale 1ns/1ps


module tb_axi_lite_slave #(
  parameter ADDR_WIDTH          = 32,
  parameter DATA_WIDTH          = 32,
  parameter STROBE_WIDTH        = (DATA_WIDTH / 8)
)(

input                               clk,
input                               rst,

//Write Address Channel
input                               AXIML_AWVALID,
input       [ADDR_WIDTH - 1: 0]     AXIML_AWADDR,
output                              AXIML_AWREADY,

//Write Data Channel
input                               AXIML_WVALID,
output                              AXIML_WREADY,
input       [STROBE_WIDTH - 1:0]    AXIML_WSTRB,
input       [DATA_WIDTH - 1: 0]     AXIML_WDATA,

//Write Response Channel
output                              AXIML_BVALID,
input                               AXIML_BREADY,
output      [1:0]                   AXIML_BRESP,

//Read Address Channel
input                               AXIML_ARVALID,
output                              AXIML_ARREADY,
input       [ADDR_WIDTH - 1: 0]     AXIML_ARADDR,

//Read Data Channel
output                              AXIML_RVALID,
input                               AXIML_RREADY,
output      [1:0]                   AXIML_RRESP,
output      [DATA_WIDTH - 1: 0]     AXIML_RDATA

);


//Local Parameters
//Registers

reg               r_rst;
reg [7:0] 	  test_id         = 0;

//Workaround for weird icarus simulator bug
always @ (*)      r_rst           = rst;

//submodules
s_axi_lite_reg#(
    .C_S_AXI_DATA_WIDTH(DATA_WIDTH),
    .C_S_AXI_ADDR_WIDTH(ADDR_WIDTH)
) dut (
    .S_AXI_ACLK(clk),
    .S_AXI_ARESETn(r_rst),   //this is a low reset!
    //address write channel
    .S_AXI_AWADDR(AXIML_AWADDR),
    .S_AXI_AWPROT(2'b00),
    .S_AXI_AWVALID(AXIML_AWVALID),
    .S_AXI_AWREADY(AXIML_AWREADY),
    //write data channel
    .S_AXI_WDATA(AXIML_WDATA),
    .S_AXI_WSTRB(AXIML_WSTRB),
    .S_AXI_WVALID(AXIML_WVALID),
    .S_AXI_WREADY(AXIML_WREADY),
    //write response channel
    .S_AXI_BRESP(AXIML_BRESP),
    .S_AXI_BVALID(AXIML_BVALID),
    .S_AXI_BREADY(AXIML_BREADY),
    //read address channel 
    .S_AXI_ARADDR(AXIML_ARADDR),
    .S_AXI_ARVALID(AXIML_ARVALID),
    .S_AXI_ARREADY(AXIML_ARREADY),
    .S_AXI_ARPROT(2'b00),
    //read data channel
    .S_AXI_RDATA(AXIML_RDATA),
    .S_AXI_RRESP(AXIML_RRESP),
    .S_AXI_RVALID(AXIML_RVALID),
    .S_AXI_RREADY(AXIML_RREADY)
);


//asynchronus logic
//synchronous logic

`ifndef VERILATOR // traced differently
  initial begin
    $dumpfile ("design.vcd");
    $dumpvars(0, tb_axi_lite_slave);
  end
`endif

endmodule
