`default_nettype none

/*
*   Author:Sebastian Jorquera
*   Correlator based in a modulated slidign DFT. 
*
*/

module axil_msdft_correlator #(
    //msdft parameters
    parameter DIN_WIDTH = 14,//8,
    parameter DIN_POINT = 13,//7,
    parameter TWIDD_WIDTH = 16, //this is limited by the axi intf... check how to change it
    parameter TWIDD_POINT = 14,
    parameter TWIDD_FILE = "twidd_init.hex",
    parameter DFT_LEN = 128,
    parameter MSDFT_WIDTH = 32,
    parameter MSDFT_POINT = 16,
    //accumulator parameters
    parameter ACC_WIDTH = 20,   //acumulator input (after the correlation mults)   
    parameter ACC_POINT = 16,
    parameter DOUT_WIDTH = 32
) (

    input wire clk, 
    input wire rst,
    input wire signed [DIN_WIDTH-1:0] din1_re, din1_im, din2_re, din2_im,
    input wire din_valid,

    output wire signed [DOUT_WIDTH-1:0] r12_re, r12_im,
    output wire [DOUT_WIDTH-1:0] r11, r22,
    output wire dout_valid,

    //delay line configuration
    input wire [31:0] delay_line,
    input wire [31:0] acc_len,

    //axil signals
    input wire axi_clock,
    input wire axil_rst,
    //write address channel
    input wire [$clog2(DFT_LEN)+1:0] s_axil_awaddr,
    input wire [2:0] s_axil_awprot,
    input wire s_axil_awvalid,
    output wire s_axil_awready,
    //write data channel
    input wire [2*TWIDD_WIDTH-1:0] s_axil_wdata,
    input wire [(2*TWIDD_WIDTH)/8-1:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output wire s_axil_wready,
    //write response channel
    output wire [1:0] s_axil_bresp,
    output wire s_axil_bvalid,
    input wire s_axil_bready,
    //read address channel
    input wire [$clog2(DFT_LEN)+1:0] s_axil_araddr,
    input wire s_axil_arvalid,
    output wire s_axil_arready,
    input wire [2:0] s_axil_arprot,
    //read data channel
    output wire [(2*TWIDD_WIDTH)-1:0] s_axil_rdata,
    output wire [1:0] s_axil_rresp,
    output wire s_axil_rvalid,
    input wire s_axil_rready
);

//rst the module inserting zeros for DFT_LEN cycles
reg [$clog2(DFT_LEN)-1:0] rst_counter=0;
reg signed [DIN_WIDTH-1:0] din1_re_r=0, din1_im_r=0, din2_re_r=0, din2_im_r=0;
reg din_valid_r=0, rst_r=0;

always@(posedge clk)begin
    if(rst)begin
        if(&rst_counter)begin
            din_valid_r <=0;
            rst_r <=1;
        end
        else begin
            din1_re_r <=0; din1_im_r <=0;
            din2_re_r <=0; din2_im_r <=0;
            din_valid_r <=1;
            rst_counter <=rst_counter+1;
            rst_r <=0;
        end
    end
    else begin
        din1_re_r<=din1_re; din1_im_r<=din1_im;
        din2_re_r<=din2_re; din2_im_r<=din2_im;
        din_valid_r<= din_valid;
        rst_counter <=0;
        rst_r <=0;
    end
end


/* We are going to use the same axi lite signals for both msdft
*/
wire signed [MSDFT_WIDTH-1:0] msdft1_re, msdft1_im;
wire msdft_valid;

axil_msdft #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .TWIDD_WIDTH(TWIDD_WIDTH),
    .TWIDD_POINT(TWIDD_POINT),
    .TWIDD_FILE(TWIDD_FILE),
    .DFT_LEN(DFT_LEN),
    .DOUT_WIDTH(MSDFT_WIDTH),
    .DOUT_POINT(MSDFT_POINT)
) axil_msdft0 (
    .clk(clk), 
    .rst(rst_r),
    .din_re(din1_re_r),
    .din_im(din1_im_r),
    .din_valid(din_valid_r),
    .dout_re(msdft1_re),
    .dout_im(msdft1_im),
    .dout_valid(msdft_valid),
    .delay_line(delay_line),
    .axi_clock(axi_clock),
    .axil_rst(axil_rst),
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
    .s_axil_rready(s_axil_rready)
);


wire signed [MSDFT_WIDTH-1:0] msdft2_re, msdft2_im;
wire msdft2_valid;

wire s_axil_awready_dummy;
wire s_axil_wready_dummy;
wire [1:0] s_axil_bresp_dummy;
wire s_axil_bvalid_dummy;
wire s_axil_arready_dummy;
wire [1:0] s_axil_arprot_dummy;
wire [TWIDD_WIDTH-1:0] s_axil_rdata_dummy;
wire s_axil_rresp_dummy;
wire s_axil_rvalid_dummy;

axil_msdft #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .TWIDD_WIDTH(TWIDD_WIDTH),
    .TWIDD_POINT(TWIDD_POINT),
    .TWIDD_FILE(TWIDD_FILE),
    .DFT_LEN(DFT_LEN),
    .DOUT_WIDTH(MSDFT_WIDTH),
    .DOUT_POINT(MSDFT_POINT)
) axil_msdft1 (
    .clk(clk), 
    .rst(rst_r),
    .din_re(din2_re_r),
    .din_im(din2_im_r),
    .din_valid(din_valid_r),
    .dout_re(msdft2_re),
    .dout_im(msdft2_im),
    .dout_valid(),
    .delay_line(delay_line),
    .axi_clock(axi_clock),
    .axil_rst(axil_rst),
    .s_axil_awaddr(s_axil_awaddr),
    .s_axil_awprot(s_axil_awprot),
    .s_axil_awvalid(s_axil_awvalid),
    .s_axil_awready(s_axil_awready_dummy),
    .s_axil_wdata(s_axil_wdata),
    .s_axil_wstrb(s_axil_wstrb),
    .s_axil_wvalid(s_axil_wvalid),
    .s_axil_wready(s_axil_wready_dummy),
    .s_axil_bresp(s_axil_bresp_dummy),
    .s_axil_bvalid(s_axil_bvalid_dummy),
    .s_axil_bready(s_axil_bready),
    .s_axil_araddr(s_axil_araddr),
    .s_axil_arvalid(s_axil_arvalid),
    .s_axil_arready(s_axil_arready_dummy),
    .s_axil_arprot(s_axil_arprot_dummy),
    .s_axil_rdata(s_axil_rdata_dummy),
    .s_axil_rresp(s_axil_rresp_dummy),
    .s_axil_rvalid(s_axil_rvalid_dummy),
    .s_axil_rready(s_axil_rready)
);

//check this part!, is to not allow the msdft_valid signal propagates 
//when the system is cleaning the internal registers
reg [11:0] rst_rr=0;
reg msdft_valid_r=0;
reg signed [MSDFT_WIDTH-1:0] msdft1_re_r=0, msdft1_im_r=0, msdft2_re_r=0, msdft2_im_r=0;
always@(posedge clk)begin
    rst_rr <= {rst_rr[10:0], rst};
    msdft_valid_r <=  msdft_valid & ~rst_rr[11];
    msdft1_re_r <= msdft1_re;
    msdft1_im_r <= msdft1_im;
    msdft2_re_r <= msdft2_re;
    msdft2_im_r <= msdft2_im;
end


wire signed [2*MSDFT_WIDTH:0] corr_re, corr_im;
wire [2*MSDFT_WIDTH:0] din1_pow, din2_pow;
wire corr_valid;

correlation_mults #(
    .DIN_WIDTH(MSDFT_WIDTH)
) corr_mults_inst (
    .clk(clk),
    .din1_re(msdft1_re_r),
    .din1_im(msdft1_im_r),
    .din2_re(msdft2_re_r),
    .din2_im(msdft2_im_r),
    .din_valid(msdft_valid_r),
    .din1_pow(din1_pow), 
    .din2_pow(din2_pow),
    .corr_re(corr_re), 
    .corr_im(corr_im),
    .dout_valid(corr_valid)
);

//cast the corr output to match the acc input
wire signed [ACC_WIDTH-1:0] acc_r12_re, acc_r12_im;
wire [ACC_WIDTH-1:0] acc_r11, acc_r22;
wire acc_in_valid;

signed_cast #(
    .DIN_WIDTH(2*MSDFT_WIDTH+1),
    .DIN_POINT(2*MSDFT_POINT),
    .DOUT_WIDTH(ACC_WIDTH),
    .DOUT_POINT(ACC_POINT)
) corr_re_cast(
    .clk(clk),
    .din(corr_re),
    .din_valid(corr_valid),
    .dout(acc_r12_re),
    .dout_valid(acc_in_valid)
);

signed_cast #(
    .DIN_WIDTH(2*MSDFT_WIDTH+1),
    .DIN_POINT(2*MSDFT_POINT),
    .DOUT_WIDTH(ACC_WIDTH),
    .DOUT_POINT(ACC_POINT)
) corr_im_cast(
    .clk(clk),
    .din(corr_im),
    .din_valid(corr_valid),
    .dout(acc_r12_im),
    .dout_valid()
);

unsign_cast #(
    .DIN_WIDTH(2*MSDFT_WIDTH+1),
    .DIN_POINT(2*MSDFT_POINT),
    .DOUT_WIDTH(ACC_WIDTH),
    .DOUT_POINT(ACC_POINT)
) din1_pow_cast(
    .clk(clk),
    .din(din1_pow),
    .din_valid(corr_valid),
    .dout(acc_r11),
    .dout_valid()
);

unsign_cast #(
    .DIN_WIDTH(2*MSDFT_WIDTH+1),
    .DIN_POINT(2*MSDFT_POINT),
    .DOUT_WIDTH(ACC_WIDTH),
    .DOUT_POINT(ACC_POINT)
) din2_pow_cast(
    .clk(clk),
    .din(din2_pow),
    .din_valid(corr_valid),
    .dout(acc_r22),
    .dout_valid()
);


//accumulators
reg [31:0] acc_len_counter=1;
reg acc_done=0;
always@(posedge clk)begin
    if(rst)begin
        acc_len_counter <=1;
        acc_done <= 1;          //discard any accumulation
    end
    else if(acc_in_valid)begin
        if(acc_len_counter == acc_len)begin
            acc_done <=1;
            acc_len_counter <=1;
        end
        else begin
            acc_done <=0;
            acc_len_counter <= acc_len_counter+1;
        end
    end 
    else begin
        acc_done <=0;
    end
end


scalar_accumulator #(
    .DIN_WIDTH(ACC_WIDTH), 
    .ACC_WIDTH(DOUT_WIDTH),
    .DATA_TYPE("signed")
) acc_corr_re (
    .clk(clk),
    .din(acc_r12_re),
    .din_valid(acc_in_valid),
    .acc_done(acc_done),
    .dout(r12_re),
    .dout_valid(dout_valid)
);

scalar_accumulator #(
    .DIN_WIDTH(ACC_WIDTH), 
    .ACC_WIDTH(DOUT_WIDTH),
    .DATA_TYPE("signed")
) acc_corr_im (
    .clk(clk),
    .din(acc_r12_im),
    .din_valid(acc_in_valid),
    .acc_done(acc_done),
    .dout(r12_im),
    .dout_valid()
);

scalar_accumulator #(
    .DIN_WIDTH(ACC_WIDTH), 
    .ACC_WIDTH(DOUT_WIDTH),
    .DATA_TYPE("unsigned")
) acc_pow1 (
    .clk(clk),
    .din(acc_r11),
    .din_valid(acc_in_valid),
    .acc_done(acc_done),
    .dout(r11),
    .dout_valid()
);

scalar_accumulator #(
    .DIN_WIDTH(ACC_WIDTH), 
    .ACC_WIDTH(DOUT_WIDTH),
    .DATA_TYPE("unsigned")
) acc_pow2 (
    .clk(clk),
    .din(acc_r22),
    .din_valid(acc_in_valid),
    .acc_done(acc_done),
    .dout(r22),
    .dout_valid()
);


endmodule
