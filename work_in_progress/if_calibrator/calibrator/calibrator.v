`default_nettype none

module calibrator #(
    parameter DIN_WIDTH = 18,
    parameter DIN_POINT = 17,
    parameter VECTOR_LEN = 512,
    parameter COEFF_WIDTH = 32, //could be 16,32
    parameter COEFF_POINT = 20,
    parameter DOUT_WIDTH = 18,
    parameter DOUT_POINT = 17,
    //
    parameter BRAM_DELAY = 0,
    parameter DOUT_DELAY = 0,
    parameter DOUT_SHIFT = 0,
    parameter DEBUG = 0,
    //axi parameters
    parameter FPGA_DATA_WIDTH = 4*COEFF_WIDTH,
    parameter FPGA_ADDR_WIDTH = $clog2(VECTOR_LEN),
    parameter AXI_DATA_WIDTH = 32,
    parameter DEINTERLEAVE = FPGA_DATA_WIDTH/AXI_DATA_WIDTH,
    parameter AXI_ADDR_WIDTH = FPGA_ADDR_WIDTH+$clog2(DEINTERLEAVE),
	parameter INIT_FILE = "",
    parameter RAM_TYPE="TRUE"
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din0_re, din0_im, din1_re, din1_im,
    input wire din_valid,
    input wire sync_in,

    output wire signed [DOUT_WIDTH-1:0] dout_re, dout_im,
    output wire dout_valid,
    output wire sync_out,
    //debug
    output wire ovf_flag,
    //axilite signals
    input wire axi_clock,
    input wire axi_reset,

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

reg [FPGA_ADDR_WIDTH-1:0] bram_addr=0;  //check!
always@(posedge clk)begin
    if(sync_in)
        bram_addr <=0;
    else if(din_valid)
        bram_addr <= bram_addr+1;
end

wire [COEFF_WIDTH-1:0] cal0_re, cal0_im, cal1_re, cal1_im;
axil_bram_unbalanced #(
    .FPGA_DATA_WIDTH(FPGA_DATA_WIDTH),
    .FPGA_ADDR_WIDTH(FPGA_ADDR_WIDTH),
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .DEINTERLEAVE(DEINTERLEAVE),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .INIT_FILE(INIT_FILE),
    .RAM_TYPE(RAM_TYPE)
) axil_bram_inst (
    .axi_clock(axi_clock), 
    .rst(axi_reset), 
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
    //fpga side
    .fpga_clk(clk),
    .bram_din(),
    .bram_addr(bram_addr),
    .bram_we(1'b0),
    .bram_dout({cal1_im,cal1_re,cal0_im, cal0_re})
);

reg signed [DIN_WIDTH-1:0] din0_re_r=0, din0_im_r=0, din1_re_r=0, din1_im_r=0;
reg din_valid_r;
always@(posedge clk)begin
    din_valid_r <= din_valid;
    if(din_valid)begin
        din0_re_r <= din0_re;   din0_im_r <= din0_im;
        din1_re_r <= din1_re;   din1_im_r <= din1_im;
    end
end

//6 cycles
wire signed [DIN_WIDTH+COEFF_WIDTH:0] mult0_re, mult0_im, mult1_re, mult1_im;
wire mult_valid;
complex_mult #(
    .DIN1_WIDTH(DIN_WIDTH),
    .DIN2_WIDTH(COEFF_WIDTH)
) complex_mult_inst [1:0] (
    .clk(clk),
    .din1_re({din0_re_r, din1_re_r}),
    .din1_im({din0_im_r, din1_im_r}),
    .din2_re({cal0_re, cal1_re}),
    .din2_im({cal0_im, cal1_im}),
    .din_valid(din_valid_r),
    .dout_re({mult0_re, mult1_re}),
    .dout_im({mult0_im, mult1_im}),
    .dout_valid(mult_valid)
);


//delay for the sync signal
wire sync_mult;
delay #(
    .DATA_WIDTH(1),
    .DELAY_VALUE(6)
) delay_power (
    .clk(clk),
    .din(sync_in),
    .dout(sync_mult)
);


//resize the output mult output
wire signed [DOUT_WIDTH-1:0] mult0_re_r, mult0_im_r, mult1_re_r, mult1_im_r;
wire sync_mult_r, mult_valid_r;

resize_data #(
    .DIN_WIDTH(DIN_WIDTH+COEFF_WIDTH+1),
    .DIN_POINT(DIN_POINT+COEFF_POINT),
    .DATA_TYPE("signed"),
    .PARALLEL(1),
    .SHIFT(DOUT_SHIFT),
    .DELAY(BRAM_DELAY),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT),
    .DEBUG(DEBUG)
) resize_mult [3:0] (
    .clk(clk), 
    .din({mult0_re, mult0_im, mult1_re, mult1_im}),
    .din_valid(mult_valid),
    .sync_in(sync_mult),
    .dout({mult0_re_r, mult0_im_r, mult1_re_r, mult1_im_r}),
    .dout_valid(mult_valid_r),
    .sync_out(sync_mult_r),
    .warning(ovf_flag)
);

reg signed [DOUT_WIDTH-1:0] dout_re_r=0, dout_im_r=0;
reg dout_valid_r=0, sync_out_r=0;
always@(posedge clk)begin
    dout_re_r <= $signed(mult0_re_r)+$signed(mult1_re_r);
    dout_im_r <= $signed(mult0_im_r)+$signed(mult1_im_r);
    dout_valid_r <= mult_valid_r;
    sync_out_r <= sync_mult_r;
end


delay #(
    .DATA_WIDTH(2*DOUT_WIDTH+2),
    .DELAY_VALUE(DOUT_DELAY)
) delay_dout (
    .clk(clk),
    .din({dout_re_r, dout_im_r, dout_valid_r, sync_out_r}),
    .dout({dout_re, dout_im, dout_valid, sync_out})
);




endmodule
