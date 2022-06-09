`default_nettype none


module band_doa_no_la #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    parameter BANDS = 4,
    //correlator parameters
    parameter PRE_ACC_SHIFT = 2,    //positive <<, negative >>
    parameter PRE_ACC_DELAY = 2,
    parameter VECTOR_LEN = 64,
    parameter ACC_WIDTH = 20,
    parameter ACC_POINT = 16,
    parameter DOUT_WIDTH = 32
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din1_re, din1_im,
    input wire signed [DIN_WIDTH-1:0] din2_re, din2_im,
    input wire din_valid,

    input wire new_acc,     //new acc should come previos the first value of the frame
    output wire signed [DOUT_WIDTH-1:0] r11,r22,r12_re,r12_im,
    output wire dout_valid,
    output wire [$clog2(BANDS)-1:0] band_number
);

//register inputs
reg [DIN_WIDTH-1:0] din1re=0, din1im=0, din2re=0, din2im=0;
reg dinvalid=0;
always@(posedge clk)begin
    din1re <= din1_re;  din1im <= din1_im;
    din2re <= din2_re;  din2im <= din2_im;
    dinvalid <= din_valid;
end

//centrosymetric transformation
wire signed [DIN_WIDTH:0] y1_re, y1_im, y2_re, y2_im;
wire centrosym_valid;

centrosym_matrix #(
    .DIN_WIDTH(DIN_WIDTH)
)centrosym_inst  (
    .clk(clk),
    .din1_re(din1re),
    .din1_im(din1im),
    .din2_re(din2re),
    .din2_im(din2im),
    .din_valid(dinvalid),
    .y1_re(y1_re),
    .y1_im(y1_im),
    .y2_re(y2_re),
    .y2_im(y2_im),
    .dout_valid(centrosym_valid)
);

//align the new acc with the centrosym data 
reg [2:0] new_acc_r=0;
always@(posedge clk)begin
    new_acc_r <= {new_acc_r[1:0], new_acc};
end

//correlators
wire signed [2*(DIN_WIDTH+1):0] r11_mult,r22_mult,r12_re_mult,r12_im_mult;
wire signed corr_valid;

correlation_mults #(
    .DIN_WIDTH(DIN_WIDTH+1)
) correlation_mults_inst (
    .clk(clk),
    .din1_re(y1_re),
    .din1_im(y1_im),
    .din2_re(y2_re),
    .din2_im(y2_im),
    .din_valid(centrosym_valid),
    .din1_pow(r11_mult),
    .din2_pow(r22_mult),
    .corr_re(r12_re_mult),
    .corr_im(r12_im_mult),
    .dout_valid(corr_valid)
);

//shift previous the cast
wire signed [2*(DIN_WIDTH+1):0] r11_data, r22_data,r12_data;
wire correlation_valid;


generate
reg signed [2*(DIN_WIDTH+1):0] r11_r=0, r12_r=0, r22_r=0;
reg corr_valid_r=0;

assign r11_data = r11_r;
assign r22_data = r22_r;
assign r12_data = r12_r;
if(PRE_ACC_SHIFT==0)begin
    always@(posedge clk)begin
        r11_r <= r11_mult;
        r12_r <= r12_re_mult;
        r22_r <= r22_mult;
        corr_valid_r <= corr_valid;
    end
end
if(PRE_ACC_SHIFT>0)begin
    always@(posedge clk)begin
        r11_r <= r11_mult<<<(PRE_ACC_SHIFT);
        r12_r <= r12_re_mult<<<(PRE_ACC_SHIFT);
        r22_r <= r22_mult<<<(PRE_ACC_SHIFT);
        corr_valid_r <= corr_valid;
    end
end
else begin
    always@(posedge clk)begin
        r11_r <= r11_mult<<<(-PRE_ACC_SHIFT);
        r12_r <= r12_re_mult<<<(-PRE_ACC_SHIFT);
        r22_r <= r22_mult<<<(-PRE_ACC_SHIFT);
        corr_valid_r <= corr_valid;
    end
end
endgenerate


wire signed [ACC_WIDTH-1:0] r11_cast, r22_cast, r12_cast;
wire [2:0] corr_cast_valid;

signed_cast #(
    .DIN_WIDTH(2*(DIN_WIDTH+1)+1),
    .DIN_POINT(2*DIN_POINT),
    .DOUT_WIDTH(ACC_WIDTH),
    .DOUT_POINT(ACC_POINT)
)corr_cast_inst [2:0] (
    .clk(clk), 
    .din({r11_data,r22_data,r12_data}),
    .din_valid(correlation_valid),
    .dout({r11_cast, r22_cast, r12_cast}),
    .dout_valid(corr_cast_valid)
);

//delay to match the correlation mults
// 7 mults+1 shift + 1 convertion   check!!!
reg [8:0] new_acc_rr;
wire new_acc_signal = new_acc_rr[8];
always@(posedge clk)begin
    new_acc_rr <= {new_acc_rr[5:0], new_acc_r};
end

//delay pre accumulators
wire signed [ACC_WIDTH-1:0] r11_delay, r22_delay, r12_delay;
wire new_acc_delay, corr_valid_delay;
generate 
if(PRE_ACC_DELAY==0)begin
    assign new_acc_delay = new_acc_signal;
    assign corr_valid_delay = corr_cast_valid;
    assign r11_delay = r11_cast;
    assign r12_delay = r12_cast;
    assign r22_delay = r22_cast;
end
else if(PRE_ACC_DELAY==1)begin
    reg signed [ACC_WIDTH-1:0] r11_temp=0, r22_temp=0, r12_temp=0;
    reg new_acc_temp=0, corr_valid_temp=0;

    assign new_acc_delay = new_acc_temp;
    assign corr_valid_delay = corr_valid_temp;
    assign r11_delay = r11_temp;
    assign r12_delay = r12_temp;
    assign r22_delay = r22_temp;
    always@(posedge clk)begin
        r11_temp <= r11_cast;
        r22_temp <= r22_cast;
        r12_temp <= r12_cast;
        new_acc_temp <= new_acc_signal;
        corr_valid_temp <= corr_cast_valid;
    end
end
else begin
    reg signed [PRE_ACC_DELAY*ACC_WIDTH-1:0] r11_temp=0, r22_temp=0, r12_temp=0;
    reg [PRE_ACC_DELAY-1:0] new_acc_temp=0, corr_valid_temp=0;

    assign new_acc_delay = new_acc_temp[PRE_ACC_DELAY-1];
    assign corr_valid_delay = corr_valid_temp[PRE_ACC_DELAY-1];
    assign r11_delay = r11_temp[PRE_ACC_DELAY*ACC_WIDTH-1:(PRE_ACC_DELAY-1)*ACC_WIDTH];
    assign r12_delay = r12_temp[PRE_ACC_DELAY*ACC_WIDTH-1:(PRE_ACC_DELAY-1)*ACC_WIDTH];
    assign r22_delay = r22_temp[PRE_ACC_DELAY*ACC_WIDTH-1:(PRE_ACC_DELAY-1)*ACC_WIDTH];
    always@(posedge clk)begin
        r11_temp <= {r11_temp[(PRE_ACC_DELAY-1)*ACC_WIDTH-1:0],r11_cast};
        r22_temp <= {r22_temp[(PRE_ACC_DELAY-1)*ACC_WIDTH-1:0],r22_cast};
        r12_temp <= {r12_temp[(PRE_ACC_DELAY-1)*ACC_WIDTH-1:0],r12_cast};
        new_acc_temp <= {new_acc_temp[PRE_ACC_SHIFT-2:0], new_acc_signal};
        corr_valid_temp <= {corr_valid_temp[PRE_ACC_DELAY-2:0], corr_cast_valid};
    end
end

endgenerate

//put the damns accumulators
reg [$clog2(BANDS)-1:0] band_count=0;
always@(posedge clk)begin
    if(corr_cast_valid[0])begin
        if(new_acc_delay)
            band_count <= 0;
        else
            band_count <= band_count+1;
    end
end

wire [BANDS*DOUT_WIDTH-1:0] r11_out, r22_out, r12_out;
wire [BANDS-1:0] acc_valid;

genvar i;
generate
localparam BAND_STEP = VECTOR_LEN/BANDS;
for(i=0; i<BANDS; i=i+1)begin: band_acc_loop

    wire valid_band;
    assign valid_band = corr_valid_delay & (band_count>i*BAND_STEP) & (band_count<(i+1)*BAND_STEP);
    
    reg band_new_acc=0;
    always@(posedge clk)begin
        if(corr_valid_delay & new_acc_delay)
            band_new_acc <= 1;
        else if(valid_band)
            band_new_acc <=0;
    end

    signed_acc #(
        .DIN_WIDTH(ACC_WIDTH),
        .ACC_WIDTH(DOUT_WIDTH)
    ) r11_acc_inst(
        .clk(clk),
        .din(r11_delay),
        .din_valid(valid_band),
        .acc_done(band_new_acc),
        .dout(r11_out[DOUT_WIDTH*i+:DOUT_WIDTH]),
        .dout_valid(acc_valid[i])
    );
    
    signed_acc #(
        .DIN_WIDTH(ACC_WIDTH),
        .ACC_WIDTH(DOUT_WIDTH)
    ) r22_acc_inst(
        .clk(clk),
        .din(r22_delay),
        .din_valid(valid_band),
        .acc_done(band_new_acc),
        .dout(r22_out[DOUT_WIDTH*i+:DOUT_WIDTH]),
        .dout_valid()
    );


    signed_acc #(
        .DIN_WIDTH(ACC_WIDTH),
        .ACC_WIDTH(DOUT_WIDTH)
    ) r12_acc_inst(
        .clk(clk),
        .din(r12_delay),
        .din_valid(valid_band),
        .acc_done(band_new_acc),
        .dout(r12_out[DOUT_WIDTH*i+:DOUT_WIDTH]),
        .dout_valid()
    );
end
endgenerate





endmodule
