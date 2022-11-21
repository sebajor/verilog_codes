`default_nettype none

/*
*   Author: Sebastian Jorquera
*   Single lane of one spectrometer, it takes the output of one FFT lane,
*   calculate the power of the complex input, then accumulate the data and
*   finally write into a bram
*/

module spectrometer_lane #(
    parameter DIN_WIDTH = 18,
    parameter DIN_POINT = 17,
    parameter VECTOR_LEN = 512,
    parameter POWER_DOUT = 2*DIN_WIDTH,
    parameter POWER_DELAY = 2,              //delay after the power computation
    parameter POWER_SHIFT = 0,
    parameter ACC_DIN_WIDTH = 2*DIN_WIDTH,
    parameter ACC_DIN_POINT = 2*DIN_POINT,
    parameter ACC_DOUT_WIDTH = 64,
    parameter DOUT_CAST_SHIFT = 0,
    parameter DOUT_CAST_DELAY = 0,
    parameter DOUT_WIDTH = 64,
    parameter DOUT_POINT = 2*DIN_POINT
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din_re, din_im,
    input wire sync_in,
    input wire [31:0] acc_len,
    input wire cnt_rst,

    //axi signals 
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
)


wire [POWER_DOUT-1:0] power_dout;
wire power_sync;
complex_power #(
    .DIN_WIDTH(DIN_WIDTH)
) complex_power_inst (
    .clk(clk),
    .din_re(din_re),
    .din_im(din_im),
    .din_valid(sync_in),
    .dout(power_dout),
    .dout_valid(power_sync)
);


wire [ACC_DIN_WIDTH-1:0] acc_in;
wire acc_sync_in;
wire power_cast_warning;

resize_data #(
    .DIN_WIDTH(POWER_DOUT),
    .DIN_POINT(2*DIN_POINT),
    .DATA_TYPE("unsigned"),
    .PARALLEL(1),
    .SHIFT(POWER_SHIFT)
    .DELAY(POWER_DELAY)
    .DOUT_WIDTH(ACC_DIN_WIDTH)
    .DOUT_POINT(ACC_DIN_POINT)
    .DEBUG(DEBUG)
) resize_power (
    .clk(clk), 
    .din(power_dout),
    .din_valid(),
    .sync_in(power_sync),
    .dout(acc_in),
    .dout_valid(),
    .sync_out(acc_sync_in),
    .warning(power_cast_warning)
);



//generate the new accumulation signal
wire new_acc= (counter==(acc_len<<$clog2(VECTOR_LEN))):
reg [31:0] counter=0;
reg first_sync=0;

//check if we need to start in 0 or in 2**32-1
always@(posedge clk)begin
    if(cnt_rst)begin
        counter <=0;
        first_sync<=0;
    end
    else begin
        first_sync <= acc_sync_in;
        if(~fist_sync & acc_sync_in)
            counter<=0;
        else if(counter == (acc_len<<$clog2(VECTOR_LEN)))
            counter <=0;
        else
            counter <=counter+1;
    end
end



vector_accumulator #(
    .DIN_WIDTH(ACC_DIN_WIDTH),
    .VECTOR_LEN(VECTOR_LEN),
    .DOUT_WIDTH(ACC_DOUT_WIDTH),
    .DATA_TYPE("unsigned")
) vector_accumulator_inst (
    .clk(),
    .new_acc(),     //new accumulation, set it previous the first sample of the frame
    .din(),
    .din_valid(),
    .dout(),
    .dout_valid()
);












axil_bram_unbalanced #(
    .FPGA_DATA_WIDTH(DOUT_WIDTH),
    .FPGA_ADDR_WIDTH($clog2(VECTOR_LEN)),
    .AXI_DATA_WIDTH(32)
)axil_bram_inst (
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
    .bram_addr(),
    .bram_we(),
    .bram_dout()
);
