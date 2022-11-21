`default_nettype none
`include "includes.v"

/*
*   
*
*/


module dss_synthesis #(
    parameter DIN_WIDTH = 18,
    parameter DIN_POINT = 17,
    parameter COEFF_WIDTH = 32,
    parameter COEFF_POINT = 27,
    parameter VECTOR_LEN = 256,
    parameter SHIFT = 0,
    parameter CAST_DELAY = 1,
    parameter DOUT_WIDTH = 18,
    parameter DOUT_POINT = 17,
    //axilite parameters
    parameter AXI_DATA_WIDTH = 32,
    parameter AXI_ADDR_WIDTH = $clog2(VECTOR_LEN)+2*DIN_WIDTH/AXI_DATA_WIDTH,
    parameter DEBUG = 1
) (
    input wire clk,
    input wire sync_in,
    input wire cnt_rst,

    input wire signed [DIN_WIDTH-1:0] din_re, din_im,
    input wire din_valid,

    output wire [DOUT_WIDTH-1:0] dout_re, dout_im,
    output wire sync_out,
    output wire dout_valid,
    
    output wire cast_warning,

    //axilite bram signals

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
    input wire s_axil_rready
);

reg [$clog2(VECTOR_LEN)-1:0] counter= {($clog2(VECTOR_LEN)){1'b1}};
always@(posedge clk)begin
    if(sync_in | cnt_rst)
        counter <= {($clog2(VECTOR_LEN)){1'b1}};
    else
        counter <= counter+1;
end

wire signed [COEFF_WIDTH-1:0] bram_re, bram_im;

axil_bram_unbalanced #(
    .FPGA_DATA_WIDTH(2*COEFF_WIDTH),
    .FPGA_ADDR_WIDTH($clog2(VECTOR_LEN)),
    .AXI_DATA_WIDTH(32)
) axil_bram_unbalanced (
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
    .fpga_clk(clk),
    .bram_din(),
    .bram_addr(counter),
    .bram_we(1'b0),
    .bram_dout({bram_im, bram_re})
);


wire signed [DIN_WIDTH-1:0] din_re_r, din_im_r;
wire sync_r;

delay #(
    .DATA_WIDTH(2*DIN_WIDTH+1),
    .DELAY_VALUE(1)  //check!
) delay_inst (
    .clk(clk),
    .din({din_im, din_re, sync_in}),
    .dout({din_im_r, din_re_r, sync_r})
);

reg complex_valid_in;
always@(posedge clk)begin
    if(cnt_rst)
        complex_valid_in <=0;
    else if(sync_r)
        complex_valid_in <=1;
end


wire signed [DIN_WIDTH+COEFF_WIDTH:0] complex_re, complex_im;
wire complex_valid_out;
wire complex_sync_out;

//match the sync out
delay #(
    .DATA_WIDTH(1),
    .DELAY_VALUE(6)  //check!
) delay_sync (
    .clk(clk),
    .din(sync_r),
    .dout(complex_sync_out)
);

complex_mult #(
    .DIN1_WIDTH(DIN_WIDTH),
    .DIN2_WIDTH(COEFF_WIDTH)
) complex_mult_inst (
    .clk(clk),
    .din1_re(din_re_r),
    .din1_im(din_im_r),
    .din2_re(bram_re),
    .din2_im(bram_im),
    .din_valid(complex_valid_in),
    .dout_re(complex_re),
    .dout_im(complex_im),
    .dout_valid(complex_valid_out)
);

localparam MULT_POINT = DIN_POINT+COEFF_POINT;

resize_data #(
    .DIN_WIDTH(DIN_WIDTH+COEFF_WIDTH+1),
    .DIN_POINT(MULT_POINT),
    .DATA_TYPE("signed"),
    .PARALLEL(2),
    .SHIFT(SHIFT),
    .DELAY(CAST_DELAY),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT),
    .DEBUG(DEBUG)
) resize_data_inst (
    .clk(clk), 
    .din({complex_re, complex_im}),
    .din_valid(complex_valid_out),
    .sync_in(complex_sync_out),
    .dout({dout_re, dout_im}),
    .dout_valid(dout_valid),
    .sync_out(sync_out),
    .warning(cast_warning)
);
 

endmodule
