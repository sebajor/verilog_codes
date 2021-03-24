`default_nettype none
`include "head.v"



module top_level #(
    parameter CLK_FREQ = 25_000_000,
    parameter C_S_AXI_ADDR_WIDTH = 8,
    parameter C_S_AXI_DATA_WIDTH = 32
) (
    //configuration of the camera
    input wire clk,
    output wire sioc, //should be pulled up
    output wire siod, //shud be pulled up
    
    //output that the config is ready, drive it to a led or something
    output wire config_done,

    //input camera
    input wire pclk,
    input wire [7:0] pdata,
    input wire vsync, 
    input wire href,    
    //axi signals  
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
    input wire S_AXI_RREADY
);


wire [15:0] pxl_r_data;
wire [18:0] pxl_r_addr;
wire en_save, rst_pxl_save, en_config;


 axi_read #(
    .C_S_AXI_DATA_WIDTH(32),
    .C_S_AXI_ADDR_WIDTH(8)
) axi_read_inst (
    //user signals
    .pxl_data(pxl_r_data), //addr0
    .pxl_addr(pxl_r_addr),//addr1
    .en_save(en_save),        //addr2[0]
    .rst_pxl_save(rst_pxl_save),   //addr3[1]
    .en_config(en_config),
    //axi signals
    .S_AXI_ACLK(clk),
    .S_AXI_ARESETn(S_AXI_ARESETn),
    //address write channel
    .S_AXI_AWADDR(S_AXI_AWADDR),
    .S_AXI_AWPROT(S_AXI_AWPROT),
    .S_AXI_AWVALID(S_AXI_AWVALID),
    .S_AXI_AWREADY(S_AXI_AWREADY),
    //write data channel
    .S_AXI_WDATA(S_AXI_WDATA),
    .S_AXI_WSTRB(S_AXI_WSTRB),
    .S_AXI_WVALID(S_AXI_WVALID),
    .S_AXI_WREADY(S_AXI_WREADY),
    //write response channel
    .S_AXI_BRESP(S_AXI_BRESP),
    .S_AXI_BVALID(S_AXI_BVALID),
    .S_AXI_BREADY(S_AXI_BREADY),
    //read address channel 
    .S_AXI_ARADDR(S_AXI_ARADDR),
    .S_AXI_ARVALID(S_AXI_ARVALID),
    .S_AXI_ARREADY(S_AXI_ARREADY),
    .S_AXI_ARPROT(S_AXI_ARPROT),
    //read data channel
    .S_AXI_RDATA(S_AXI_RDATA),
    .S_AXI_RRESP(S_AXI_RRESP),
    .S_AXI_RVALID(S_AXI_RVALID),
    .S_AXI_RREADY(S_AXI_RREADY)
);


camera_configure #( .CLK_FREQ(CLK_FREQ)
    ) cam_config_inst (
    .clk(clk),
    .sioc(sioc),
    .siod(siod),
    .start(en_config),
    .done(config_done)
    );
 

wire [15:0] pxl_data;
wire pxl_valid, frame_done;
wire [18:0] pxl_addr;

OV7670_RGB565 OV7670_RGB565_inst (
    .pclk(pclk),
    .vsync(vsync),
    .href(href),
    .pdata(pdata),
    .pxl_data(pxl_data),
    .pxl_valid(pxl_valid),
    .frame_done(frame_done),
    .pxl_addr(pxl_addr)
);

wire pxl_r_valid;

save_frame save_frame_inst (
    //camera data
    .pclk(pclk),
    .pxl_valid(pxl_valid),
    .frame_done(frame_done),
    .pdata(pxl_data),
    .pxl_addr(pxl_addr),
    //read data
    .en_save(en_save),
    .rst(rst_pxl_save),
    .r_clk(clk),
    .read_addr(pxl_r_addr),
    .pxl_r_data(pxl_r_data),
    .pxl_r_valid(pxl_r_valid)
);

endmodule
