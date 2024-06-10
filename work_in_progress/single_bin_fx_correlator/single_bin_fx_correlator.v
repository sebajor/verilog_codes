`default_nettype none

/*
*   Author: Sebastian Jorquera
*   Single DFT bin correlator. You can moidfy the twiddle
*   factor with a axilite interface. The twiddle factors are stored
*   in a 64bits bram where the lower 32 bits represents the real part and the
*   upper bits are the imaginary ones. The twiddle factors are resized to match
*   the TWIDD_WIDTH set in the parameters.
*   You can also limit the DFT size using the delay_line port 
*   (should be set to DFT_size requested-1)
*/

module single_bin_fx_correlator #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 15,
    parameter PARALLEL_INPUTS = 2,
    parameter TWIDD_WIDTH = 16,
    parameter TWIDD_POINT = 14,
    parameter TWIDD_FILE = "twidd_init.bin",
    parameter TWIDD_DELAY = 1,
    parameter ACC_DELAY = 0,
    parameter DFT_LEN = 128,
    parameter DFT_DOUT_WIDTH = 32,
    parameter DFT_DOUT_POINT = 15,
    parameter DFT_DOUT_DELAY = 1,
    parameter ACC_WIDTH = 32,
    parameter ACC_POINT = 15,
    parameter ACC_IN_DELAY = 1,
    parameter ACC_OUT_DELAY = 1,
    parameter DOUT_WIDTH = 32,      //the bin pt of the output is the same as the ACC
    parameter REAL_INPUT_ONLY=1,
    parameter CAST_WARNING = 0 //sim only 
) (
    input wire clk,
    input wire rst, 
    input wire signed [DIN_WIDTH-1:0] din0_re, din0_im, din1_re, din1_im,

    input wire din_valid,
    
    input wire [31:0] delay_line,   //this controls the DFT size, the one at the parameter is the max value
    input wire [31:0] acc_len,
    //
    
    output wire [DOUT_WIDTH-1:0] aa, bb, 
    output wire signed [DOUT_WIDTH-1:0] ab_re, ab_im,
    output wire dout_valid,
    output wire cast_warning,
    //axilite interface
    input wire axi_clock,
    input wire axil_rst,
    //write address channel
    input wire [$clog2(DFT_LEN)+2:0] s_axil_awaddr,
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
    input wire [$clog2(DFT_LEN)+2:0] s_axil_araddr,
    input wire s_axil_arvalid,
    output wire s_axil_arready,
    input wire [2:0] s_axil_arprot,
    //read data channel
    output wire [(2*TWIDD_WIDTH)-1:0] s_axil_rdata,
    output wire [1:0] s_axil_rresp,
    output wire s_axil_rvalid,
    input wire s_axil_rready
);

wire [2*DFT_DOUT_WIDTH-1:0] dft_re, dft_im;
wire [DFT_DOUT_WIDTH-1:0] dft0_re, dft0_im, dft1_re, dft1_im;
wire dft_valid;


assign dft0_re = dft_re[0+:DFT_DOUT_WIDTH];
assign dft1_re = dft_re[DFT_DOUT_WIDTH+:DFT_DOUT_WIDTH];
assign dft0_im = dft_im[0+:DFT_DOUT_WIDTH];
assign dft1_im = dft_im[DFT_DOUT_WIDTH+:DFT_DOUT_WIDTH];

dft_bin_multiple_inputs #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .PARALLEL_INPUTS(2),
    .TWIDD_WIDTH(TWIDD_WIDTH),
    .TWIDD_POINT(TWIDD_POINT),
    .TWIDD_FILE(TWIDD_FILE),
    .TWIDD_DELAY(TWIDD_DELAY),
    .DFT_LEN(DFT_LEN),
    .ACC_DELAY(ACC_DELAY),
    .DOUT_WIDTH(DFT_DOUT_WIDTH),
    .DOUT_POINT(DFT_DOUT_POINT),
    .DOUT_DELAY(DFT_DOUT_DELAY),
    .REAL_INPUT_ONLY(REAL_INPUT_ONLY),
    .CAST_WARNING(CAST_WARNING)
) dft_bin_multiple_inputs_inst (
    .clk(clk),
    .rst(rst), 
    .din_re({din1_re, din0_re}),
    .din_im({din1_im, din0_im}),
    .din_valid(din_valid),
    .delay_line(delay_line),
    .dout_re(dft_re), 
    .dout_im(dft_im), 
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

localparam MULT_WIDTH = 2*DFT_DOUT_WIDTH+1;
localparam MULT_POINT = 2*DFT_DOUT_POINT;

wire [MULT_WIDTH-1:0] din0_pow, din1_pow;
wire signed [MULT_WIDTH-1:0] corr_re, corr_im;
wire corr_valid;

correlation_mults #(
    .DIN_WIDTH(DFT_DOUT_WIDTH)
) correlation_mults_inst (
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

//convert the data
wire signed [ACC_WIDTH-1:0] corr_re_cast, corr_im_cast;
wire [ACC_WIDTH-1:0] din0_pow_cast, din1_pow_cast;
wire corr_cast_valid;

resize_data #(
    .DIN_WIDTH(MULT_WIDTH),
    .DIN_POINT(MULT_POINT),
    .DATA_TYPE("signed"),  //signed or unsigned
    .PARALLEL(2),
    .SHIFT(0),
    .DELAY(ACC_IN_DELAY),
    .DOUT_WIDTH(ACC_WIDTH),
    .DOUT_POINT(ACC_POINT),
    .DEBUG(0)
) corr_signed_cast (
    .clk(clk), 
    .din({corr_re, corr_im}),
    .din_valid(corr_valid),
    .sync_in(),
    .dout({corr_re_cast, corr_im_cast}),
    .dout_valid(corr_cast_valid),
    .sync_out(),
    .warning()
);


resize_data #(
    .DIN_WIDTH(MULT_WIDTH),
    .DIN_POINT(MULT_POINT),
    .DATA_TYPE("unsigned"),  //signed or unsigned
    .PARALLEL(2),
    .SHIFT(0),
    .DELAY(ACC_IN_DELAY),
    .DOUT_WIDTH(ACC_WIDTH),
    .DOUT_POINT(ACC_POINT),
    .DEBUG(0)
) corr_unsigned_cast (
    .clk(clk), 
    .din({din0_pow, din1_pow}),
    .din_valid(corr_valid),
    .sync_in(),
    .dout({din0_pow_cast, din1_pow_cast}),
    .dout_valid(),
    .sync_out(),
    .warning()
);

reg [31:0] acc_counter=0;
reg acc_done=0;
always@(posedge clk)begin
    if(corr_cast_valid)begin 
        if(acc_counter==acc_len)begin
            acc_counter <= 0;
            acc_done <= 1;
        end
        else begin
            acc_counter <= acc_counter+1;
            acc_done <= 0;
        end
    end
end


//i think we need this delay
wire signed [ACC_WIDTH-1:0] corr_re_r, corr_im_r;
wire [ACC_WIDTH-1:0] pow0, pow1;
wire acc_in_valid;
delay #(
    .DATA_WIDTH(4*ACC_WIDTH+1),
    .DELAY_VALUE(0)
) acc_input_delay (
    .clk(clk),
    .din({din0_pow_cast, din1_pow_cast, corr_re_cast, corr_im_cast, corr_cast_valid}),
    .dout({pow0, pow1, corr_re_r, corr_im_r, acc_in_valid})
);

wire [1:0] acc_dout_valid;

scalar_accumulator #(
    .DIN_WIDTH(ACC_WIDTH),
    .ACC_WIDTH(DOUT_WIDTH),
    .DATA_TYPE("signed")
) acc_signed [1:0] (
    .clk(clk),
    .din({corr_re_r, corr_im_r}),
    .din_valid(acc_in_valid),
    .acc_done(acc_done),
    .dout({ab_re, ab_im}),
    .dout_valid(acc_dout_valid)
);


scalar_accumulator #(
    .DIN_WIDTH(ACC_WIDTH),
    .ACC_WIDTH(DOUT_WIDTH),
    .DATA_TYPE("unsigned")
) acc_unsigned [1:0] (
    .clk(clk),
    .din({pow0, pow1}),
    .din_valid(acc_in_valid),
    .acc_done(acc_done),
    .dout({aa,bb}),
    .dout_valid()
);

assign dout_valid = acc_dout_valid[0];

endmodule
