`default_nettype none
`include "includes.v"

/*  A correlator using 2 msdft to pass to the freq domain, then we 
calculate cross and auto correlation between the two branches.
Then we integrate the correlation outputs for a programmable number of times

*/

module msdft_correlator #(
    //msdft signals
    parameter DIN_WIDTH = 8,
    parameter DIN_POINT = 7,
    parameter TWIDD_WIDTH = 16,
    parameter TWIDD_POINT = 14,
    parameter TWIDD_FILE = "twidd.hex",
    parameter DFT_LEN = 128,
    parameter MSDFT_DOUT_WIDTH = 32,
    parameter MSDFT_DOUT_POINT = 16,
    parameter ACC_IN_WIDTH = 32,
    parameter ACC_IN_POINT = 16,
    parameter ACC_OUT_WIDTH = 64,
    parameter DOUT_WIDTH = 32,
    parameter DOUT_POINT = 16

)(
    input wire clk, 
    input wire rst,

    input wire signed [DIN_WIDTH-1:0] din1_re, din1_im, din2_re, din2_im,
    input wire din_valid,

    output wire signed [ACC_OUT_WIDTH-1:0] correlation_re, correlation_im,
    output wire [ACC_OUT_WIDTH-1:0] power1, power2,
    output wire dout_valid,

    //configuration signals
    input wire axi_clock,
    input wire [2*TWIDD_WIDTH-1:0] bram_dat,
    input wire [$clog2(DFT_LEN)-1:0] bram_addr,
    input wire bram_we,
    output wire [2*TWIDD_WIDTH-1:0] bram_dout,
    input wire [31:0] delay_line,
    input wire [31:0] acc_len
);

reg signed [DIN_WIDTH-1:0] din1_re_r=0, din1_im_r=0, din2_re_r=0, din2_im_r=0;
reg din_valid_r =0;
reg [$clog2(DFT_LEN)-1:0] rst_counter =0;
always@(posedge clk)begin
    if(rst)begin
        //if rst we clean the msdft
        if(&rst_counter)begin
            din_valid_r <=0;
            rst_counter <= rst_counter;
        end
        else begin
            rst_counter <= rst_counter+1;
            din_valid_r <= 1;
            din1_re_r <=0; din1_im_r <=0;
            din2_re_r <=0; din2_im_r <=0; 
        end
    end
    else begin
        rst_counter <=0;
        din_valid_r <= din_valid;
        din1_re_r <=din1_re; din1_im_r <=din1_im;
        din2_re_r <=din2_re; din2_im_r <=din2_im; 
    end
end

wire signed [MSDFT_DOUT_WIDTH-1:0] msdft1_re, msdft1_im, msdft2_re, msdft2_im;
wire msdft1_valid, msdft2_valid;

msdft #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .TWIDD_WIDTH(TWIDD_WIDTH),
    .TWIDD_POINT(TWIDD_POINT),
    .TWIDD_FILE(TWIDD_FILE),
    .DFT_LEN(DFT_LEN),
    .DOUT_WIDTH(MSDFT_DOUT_WIDTH),
    .DOUT_POINT(MSDFT_DOUT_POINT)
) msdft_din1 (
    .clk(clk), 
    .rst(1'b0),
    .din_re(din1_re_r), 
    .din_im(din1_im_r),
    .din_valid(din_valid_r),
    .dout_re(msdft1_re), 
    .dout_im(msdft1_im),
    .dout_valid(msdft1_valid),
    .axi_clock(axi_clock),
    .bram_dat(bram_dat),
    .bram_addr(bram_addr),
    .bram_we(bram_we),
    .bram_dout(bram_dout),
    .delay_line(delay_line)
);

msdft #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .TWIDD_WIDTH(TWIDD_WIDTH),
    .TWIDD_POINT(TWIDD_POINT),
    .TWIDD_FILE(TWIDD_FILE),
    .DFT_LEN(DFT_LEN),
    .DOUT_WIDTH(MSDFT_DOUT_WIDTH),
    .DOUT_POINT(MSDFT_DOUT_POINT)
) msdft_din2 (
    .clk(clk), 
    .rst(1'b0),
    .din_re(din2_re_r), 
    .din_im(din2_im_r),
    .din_valid(din_valid_r),
    .dout_re(msdft2_re), 
    .dout_im(msdft2_im),
    .dout_valid(msdft2_valid),
    .axi_clock(axi_clock),
    .bram_dat(bram_dat),
    .bram_addr(bram_addr),
    .bram_we(bram_we),
    .bram_dout(),
    .delay_line(delay_line)
);

reg signed [MSDFT_DOUT_WIDTH-1:0] msdft1_re_r=0, msdft1_im_r=0, neg_msdft1_im=0;
reg signed [MSDFT_DOUT_WIDTH-1:0] msdft2_re_r=0, msdft2_im_r=0, neg_msdft2_im=0;
reg msdft_valid=0;
always@(posedge clk)begin
    msdft1_re_r <= msdft1_re; msdft1_im_r <= msdft1_im;
    msdft2_re_r <= msdft2_re; msdft2_im_r <= msdft2_im;
    neg_msdft1_im <= ~msdft1_im+1'b1;
    neg_msdft2_im <= ~msdft2_im+1'b1;
    msdft_valid <= msdft1_valid;
end 

//cross-correlation
localparam POW_POINT = 2*MSDFT_DOUT_POINT;
wire signed [2*MSDFT_DOUT_WIDTH:0] corr_re, corr_im;
wire corr_valid;
//delay:5 cycles
complex_mult #(
    .DIN1_WIDTH(MSDFT_DOUT_WIDTH),
    .DIN2_WIDTH(MSDFT_DOUT_WIDTH)
) cross_corr (
    .clk(clk),
    .din1_re(msdft1_re_r),
    .din1_im(msdft1_im_r),
    .din2_re(msdft2_re_r),
    .din2_im(neg_msdft2_im),
    .din_valid(msdft_valid),
    .dout_re(corr_re),
    .dout_im(corr_im),
    .dout_valid(corr_valid)
);

//autocorrelations
wire [2*MSDFT_DOUT_WIDTH:0] pow1, pow2;
wire pow_valid;

complex_power #(
    .DIN_WIDTH(MSDFT_DOUT_WIDTH)
) power_din1 (
    .clk(clk),
    .din_re(msdft1_re_r),
    .din_im(msdft1_im_r),
    .din_valid(msdft_valid),
    .dout(pow1),
    .dout_valid(pow_valid)
);

complex_power #(
    .DIN_WIDTH(MSDFT_DOUT_WIDTH)
) power_din2 (
    .clk(clk),
    .din_re(msdft2_re_r),
    .din_im(msdft2_im_r),
    .din_valid(msdft_valid),
    .dout(pow2),
    .dout_valid()
);

//convert the data to the accumulation input

wire signed [ACC_IN_WIDTH-1:0] corr_re_acc, corr_im_acc;
wire corr_acc_valid;

signed_cast #(
    .DIN_WIDTH(2*MSDFT_DOUT_WIDTH+1),
    .DIN_POINT(2*MSDFT_DOUT_POINT),
    .DOUT_WIDTH(ACC_IN_WIDTH),
    .DOUT_POINT(ACC_IN_POINT)
) cast_corr_re(
    .clk(clk), 
    .din(corr_re),
    .din_valid(corr_valid),
    .dout(corr_re_acc),
    .dout_valid(corr_acc_valid)
);

signed_cast #(
    .DIN_WIDTH(2*MSDFT_DOUT_WIDTH+1),
    .DIN_POINT(2*MSDFT_DOUT_POINT),
    .DOUT_WIDTH(ACC_IN_WIDTH),
    .DOUT_POINT(ACC_IN_POINT)
) cast_corr_im(
    .clk(clk), 
    .din(corr_im),
    .din_valid(corr_valid),
    .dout(corr_im_acc),
    .dout_valid()
);


//like the power is unsigned we just need to discard the bits
localparam ACC_IN_INT = ACC_IN_WIDTH-ACC_IN_POINT;
reg [ACC_IN_WIDTH-1:0] pow1_cast=0, pow2_cast=0;
reg pow_cast_valid=0;
always@(posedge clk)begin
    pow1_cast <= {pow1[POW_POINT+:ACC_IN_INT], pow1[POW_POINT-:ACC_IN_POINT]};
    pow2_cast <= {pow2[POW_POINT+:ACC_IN_INT], pow2[POW_POINT-:ACC_IN_POINT]};
    pow_cast_valid <= pow_valid;
end

//accumulators
reg signed [ACC_OUT_WIDTH-1:0] integ_acc_re=0, integ_acc_im=0;
reg [ACC_OUT_WIDTH-1:0] integ_pow1=0, integ_pow2=0;
reg dout_valid_r=0;
reg [31:0] counter=0;
//outputs
reg signed [ACC_OUT_WIDTH-1:0] dout_acc_re=0, dout_acc_im=0;
reg [ACC_OUT_WIDTH-1:0] dout_pow1=0, dout_pow2=0;


always@(posedge clk)begin
    if(rst)begin
        counter <=0;
        integ_acc_re<=0;    integ_acc_im<=0;
        integ_pow1 <=0;     integ_pow2 <=0;
        dout_valid_r <=0;
    end
    else if(pow_valid)begin
        if(counter==acc_len)begin
            dout_valid_r <= 1;
            counter <=0;
            integ_acc_re<=0;    integ_acc_im<=0;
            integ_pow1 <=0;     integ_pow2 <=0;
        end
        else begin
            dout_valid_r <= 0;
            counter <=counter+1;
            integ_acc_re<= $signed(corr_re_acc)+$signed(integ_acc_re);
            integ_acc_im<= $signed(corr_im_acc)+$signed(integ_acc_im);
            integ_pow1 <= integ_pow1+pow1_cast; 
            integ_pow2 <= integ_pow2+pow2_cast;
        end
    end
end

always@(posedge clk)begin
    dout_acc_re <= integ_acc_re;
    dout_acc_im <= integ_acc_im;
    dout_pow1 <= integ_pow1;
    dout_pow2 <= integ_pow2;
end

assign correlation_re = dout_acc_re;
assign correlation_im = dout_acc_im;
assign power1 = dout_pow1;
assign power2 = dout_pow2;
assign dout_valid = dout_valid_r;

endmodule

