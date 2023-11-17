`default_nettype none

module single_bin_fx_correlator #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 15,
    parameter TWIDD_WIDTH = 16,
    parameter TWIDD_POINT = 14,
    parameter TWIDD_FILE = "twidd_init.bin",
    parameter TWIDD_DELAY = 1,
    parameter DFT_ACC_DELAY = 0,
    parameter DFT_LEN = 128,
    parameter DFT_DOUT_WIDTH = 32,
    parameter DFT_DOUT_POINT = 15,
    parameter DFT_DOUT_DELAY = 1,
    parameter CORR_OUT_DELAY = 0,
    parameter ACC_WIDTH = 20,
    parameter ACC_POINT = 10,
    parameter DOUT_WIDTH = 32,
    
    parameter REAL_INPUT_ONLY=0,
    parameter CAST_WARNING = 1
) (
    input wire clk,
    input wire rst, 
    input wire signed [DIN_WIDTH-1:0] din0_re, din0_im, din1_re, din1_im,
    input wire din_valid,
    
    input wire [31:0] delay_line,   //this controls the DFT size, the one at the parameter is the max value
    input wire [31:0] acc_len,

    output wire signed [DOUT_WIDTH-1:0] correlation_re, correlation_im,
    output wire [DOUT_WIDTH-1:0] power0, power1,
    output wire dout_valid,
    output wire cast_warning,
    //axilite interface
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

wire signed [DFT_DOUT_WIDTH-1:0] dft0_re, dft0_im, dft1_re, dft1_im;
wire dft_valid;

dft_bin_multiple_inputs #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .PARALLEL_INPUTS(2),
    .TWIDD_WIDTH(TWIDD_WIDTH),
    .TWIDD_POINT(TWIDD_POINT),
    .TWIDD_FILE(TWIDD_FILE),
    .TWIDD_DELAY(TWIDD_DELAY),
    .ACC_DELAY(DFT_ACC_DELAY),
    .DFT_LEN(DFT_LEN),
    .DOUT_WIDTH(DFT_DOUT_WIDTH),
    .DOUT_POINT(DFT_DOUT_POINT),
    .DOUT_DELAY(DFT_DOUT_DELAY),
    .REAL_INPUT_ONLY(REAL_INPUT_ONLY),
    .CAST_WARNING(CAST_WARNING)
)dft_bin_multiple_inputs_inst  (
    .clk(clk),
    .rst(rst), 
    .din_re({din1_re, din0_re}),
    .din_im({din1_im, din0_im}),
    .din_valid(din_valid),
    .delay_line(delay_line),
    .dout_re({dft1_re, dft0_re}),
    .dout_im({dft1_im, dft0_im}), 
    .dout_valid(dft_valid),
    .cast_warning(),
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

localparam CORR_WIDTH = 2*DFT_DOUT_WIDTH+1;
localparam CORR_POINT = 2*DFT_DOUT_POINT;

wire [CORR_WIDTH-1:0] din0_pow, din1_pow;
wire signed [CORR_WIDTH-1:0] corr_re, corr_im;
wire corr_valid;

correlation_mults #(
    .DIN_WIDTH(DFT_DOUT_WIDTH)
) corr_mults_inst (
    .clk(clk),
    .din1_re(dft0_re),
    .din1_im(dft0_im),
    .din2_re(dft1_re),
    .din2_im(dft1_im),
    .din_valid(dft_valid),
    .din1_pow(din0_pow),
    .din2_pow(din1_pow),
    .corr_re(corr_re),
    .corr_im(corr_im),
    .dout_valid(corr_valid)
);

wire [CORR_WIDTH-1:0] din0_pow_r, din1_pow_r;
wire signed [CORR_WIDTH-1:0] corr_re_r, corr_im_r;
wire corr_valid_r;
 
delay #(
    .DATA_WIDTH(4*CORR_WIDTH+1),
    .DELAY_VALUE(CORR_OUT_DELAY)
) corr_delay (
    .clk(clk),
    .din({din0_pow, din1_pow, corr_re, corr_im, corr_valid}),
    .dout({din0_pow_r, din1_pow_r, corr_re_r, corr_im_r, corr_valid_r})
);

//convert the data to ACC_WIDTH 
wire signed [ACC_WIDTH-1:0] corr_re_cast, corr_im_cast;
wire [ACC_WIDTH-1:0] pow0_cast, pow1_cast;
wire corr_cast_valid;
wire [1:0] corr_re_cast_ovf, corr_im_cast_ovf, pow0_cast_ovf, pow1_cast_ovf;

signed_cast #(
    .DIN_WIDTH(CORR_WIDTH),
    .DIN_POINT(CORR_POINT),
    .DOUT_WIDTH(ACC_WIDTH),
    .DOUT_POINT(ACC_POINT),
    .OVERFLOW_WARNING(CAST_WARNING)
) corr_cast_inst [1:0] (
    .clk(clk), 
    .din({corr_re_r, corr_im_r}),
    .din_valid(corr_valid_r),
    .dout({corr_re_cast, corr_im_cast}),
    .dout_valid(corr_cast_valid),
    .warning({corr_re_cast_ovf, corr_im_cast_ovf})
);

unsign_cast #(
    .DIN_WIDTH(CORR_WIDTH),
    .DIN_POINT(CORR_POINT),
    .DOUT_WIDTH(ACC_WIDTH),
    .DOUT_POINT(ACC_POINT),
    .OVERFLOW_WARNING(CAST_WARNING)
) pow_cast_inst [1:0] ( 
    .clk(clk), 
    .din({din0_pow_r, din1_pow_r}),
    .din_valid(corr_valid_r),
    .dout({pow0_cast, pow1_cast}),
    .dout_valid(),
    .warning({pow0_cast_ovf, pow1_cast_ovf})
);


//set the counter for the accumulator
reg [31:0] acc_counter=0;
reg acc_valid;
always@(posedge clk)begin
    if(rst)begin
        acc_counter <=0;
        acc_valid <=0;
    end
    else if(corr_cast_valid)begin
        if(acc_counter==acc_len)begin
            acc_counter <=0;
            acc_valid <= 1;
        end
        else begin
            acc_counter <= acc_counter+1;
            acc_valid <=0;
        end
    end
    else
        acc_valid <=0;
end


//we need an extra delay to match the acc_valid with the corr_valid
wire [ACC_WIDTH-1:0] din0_pow_rr, din1_pow_rr;
wire signed [ACC_WIDTH-1:0] corr_re_rr, corr_im_rr;
wire corr_valid_rr;
 
delay #(
    .DATA_WIDTH(4*ACC_WIDTH+1),
    .DELAY_VALUE(1)
) pre_acc_sync_delay (
    .clk(clk),
    .din({pow0_cast, pow1_cast, corr_re_cast, corr_im_cast, corr_cast_valid}),
    .dout({din0_pow_rr, din1_pow_rr, corr_re_rr, corr_im_rr, corr_valid_rr})
);

//accumulators

scalar_accumulator #(
    .DIN_WIDTH(ACC_WIDTH),
    .ACC_WIDTH(DOUT_WIDTH),
    .DATA_TYPE("signed")
) corr_accumulator_inst [1:0](
    .clk(clk),
    .din({corr_re_rr, corr_im_rr}),
    .din_valid(corr_valid_rr),
    .acc_done(acc_valid),
    .dout({correlation_re, correlation_im}),
    .dout_valid(dout_valid)
);

scalar_accumulator #(
    .DIN_WIDTH(ACC_WIDTH),
    .ACC_WIDTH(DOUT_WIDTH),
    .DATA_TYPE("unsigned")
) power_accumulator_inst [1:0](
    .clk(clk),
    .din({din0_pow_rr, din1_pow_rr}),
    .din_valid(corr_valid_rr),
    .acc_done(acc_valid),
    .dout({power0, power1}),
    .dout_valid()
);


endmodule
