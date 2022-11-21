`default_nettype none

module axil_bram_unbalanced #(
    parameter FPGA_DATA_WIDTH = 64,
    parameter FPGA_ADDR_WIDTH = 10,
    parameter AXI_DATA_WIDTH = 32,
    parameter DEINTERLEAVE = FPGA_DATA_WIDTH/AXI_DATA_WIDTH,
    parameter AXI_ADDR_WIDTH = FPGA_ADDR_WIDTH+$clog2(DEINTERLEAVE),
	parameter INIT_FILE = "",
    parameter RAM_TYPE="TRUE"
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



generate
    if(DEINTERLEAVE==1)begin
        axil_bram #(
            .DATA_WIDTH(FPGA_DATA_WIDTH),
            .ADDR_WIDTH(FPGA_ADDR_WIDTH),
            .INIT_FILE("")
        ) axil_bram_inst (
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
    end
    else begin
        wire [AXI_ADDR_WIDTH-1:0] arbiter_addr;
        wire arbiter_we, arbiter_en;
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
            .bram_en(arbiter_en),
            .bram_we(arbiter_we)
        );


        unbalanced_ram #(
            .DATA_WIDTH_A(FPGA_DATA_WIDTH),
            .ADDR_WIDTH_A(FPGA_ADDR_WIDTH),
            .DEINTERLEAVE(DEINTERLEAVE),
            .MUX_LATENCY(0),
            .RAM_TYPE(RAM_TYPE)
        ) unbalanced_ram (
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
            //.enb(1'b1),
            .enb(arbiter_en),
            .rstb(1'b0)
        );
    end
endgenerate

endmodule
