`default_nettype none

/*
    Author: Sebastian Jorquera

    Uesprit after FFT. But we generate bands where we calculate the doa.

    Like this module support parallel inputs first we "add" them so the max 
    available BANDS will be VECTOR_LEN/PARALLEL. 

*/

module band_doa_no_la #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    parameter PARALLEL = 4,     //parallel inputs
    parameter VECTOR_LEN = 64,      //FFT channels
    parameter BANDS = 4,            //
    //correlator  parameters
    parameter PRE_ACC_DELAY = 0,    //for timing
    parameter PRE_ACC_SHIFT = 2,    //positive <<, negative >>
    parameter ACC_WIDTH = 20,
    parameter ACC_POINT = 16,
    parameter DOUT_WIDTH = 32
) (
    input wire clk,
    input wire [PARALLEL*DIN_WIDTH-1:0] din1_re, din1_im,
    input wire [PARALLEL*DIN_WIDTH-1:0] din2_re, din2_im,
    input wire din_valid,
    input wire new_acc,     //this comes previous the first channel

    output wire signed [DOUT_WIDTH-1:0] r11,r22,r12,
    output wire dout_valid,
    output wire [$clog2(BANDS)-1:0] band_number
);

localparam MULTS_WIDTH = 2*(DIN_WIDTH+1)+1;

wire [PARALLEL*MULTS_WIDTH-1:0] pow0, pow1,corr_re;
wire [PARALLEL-1:0] corr_valid;

genvar i;
generate
    for(i=0; i<PARALLEL; i=i+1)begin: centrosym_loop
        wire [DIN_WIDTH:0] y1_re, y1_im, y2_re, y2_im;
        wire centrosym_valid;


        centrosym_matrix #(
            .DIN_WIDTH(DIN_WIDTH)
        )centrosym_inst  (
            .clk(clk),
            .din1_re(din1_re[DIN_WIDTH*i+:DIN_WIDTH]),
            .din1_im(din1_im[DIN_WIDTH*i+:DIN_WIDTH]),
            .din2_re(din2_re[DIN_WIDTH*i+:DIN_WIDTH]),
            .din2_im(din2_im[DIN_WIDTH*i+:DIN_WIDTH]),
            .din_valid(din_valid),
            .y1_re(y1_re),
            .y1_im(y1_im),
            .y2_re(y2_re),
            .y2_im(y2_im),
            .dout_valid(centrosym_valid)
        );

        //correlation between the streams
        wire signed [MULTS_WIDTH-1:0] pow0_local, pow1_local, corr_re_local;
        correlation_mults #(
            .DIN_WIDTH(DIN_WIDTH+1)
        ) correlation_mults_inst  (
            .clk(clk),
            .din1_re(y1_re), 
            .din1_im(y1_im),
            .din2_re(y2_re), 
            .din2_im(y2_im),
            .din_valid(centrosym_valid),
            .din1_pow(pow0_local),
            .din2_pow(pow1_local),
            .corr_re(corr_re_local),
            .corr_im(),
            .dout_valid(corr_valid[i])
        );
        assign pow0[MULTS_WIDTH*i+:MULTS_WIDTH] = pow0_local;
        assign pow1[MULTS_WIDTH*i+:MULTS_WIDTH] = pow1_local;
        assign corr_re[MULTS_WIDTH*i+:MULTS_WIDTH] = corr_re_local;
    end
endgenerate


wire signed [MULTS_WIDTH+$clog2(PARALLEL)-1:0] pow0_add, pow1_add, corr_re_add;
wire [2:0] adder_tree_valid;

//check this!
adder_tree #(
    .DATA_WIDTH(MULTS_WIDTH),
    .PARALLEL(PARALLEL)
) adder_tree_inst [2:0] (
    .clk(clk),
    .din({pow0, pow1, corr_re}),
    .in_valid(corr_valid[0]),
    .dout({pow0_add, pow1_add, corr_re_add}),
    .out_valid(adder_tree_valid)
);


//delay to match the adder tree    check!
wire new_acc_mult;  
delay #(
    .DATA_WIDTH(1),
    .DELAY_VALUE(9+$clog2(PARALLEL))
) delay_mult_corrs (
    .clk(clk),
    .din(new_acc),
    .dout(new_acc_mult)
);


//shift, convertion and delay previous the accumulation

wire signed [MULTS_WIDTH+$clog2(PARALLEL)-1:0] pow0_shift, pow1_shift, corr_re_shift;
shift #(
    .DATA_WIDTH(MULTS_WIDTH+$clog2(PARALLEL)),
    .DATA_TYPE("signed"), //"signed" or "unsigned"
    .SHIFT_VALUE(PRE_ACC_SHIFT),      //positive <<, negative >>
    .ASYNC(0)             // 
) shift_pre_acc_inst [2:0] (
    .clk(clk),
    .din({pow0_add,pow1_add, corr_re_add}),
    .dout({pow0_shift, pow1_shift, corr_re_shift})
);

reg shift_valid=0;
reg new_acc_shift =0;
always@(posedge clk)begin
    shift_valid <= adder_tree_valid[0];
    new_acc_shift <= new_acc_mult;
end


wire signed [ACC_WIDTH-1:0] pow0_cast, pow1_cast, corr_re_cast;
wire [2:0] cast_valid;

signed_cast #(
    .DIN_WIDTH(MULTS_WIDTH+$clog2(PARALLEL)),
    .DIN_POINT(2*DIN_POINT),
    .DOUT_WIDTH(ACC_WIDTH),
    .DOUT_POINT(ACC_POINT)
) pre_acc_cast_inst [2:0] (
    .clk(clk), 
    .din({pow0_shift, pow1_shift, corr_re_shift}),
    .din_valid(shift_valid),
    .dout({pow0_cast, pow1_cast, corr_re_cast}),
    .dout_valid(cast_valid)
);

wire signed [ACC_WIDTH-1:0] pow0_delay, pow1_delay, corr_re_delay;
wire delay_valid;

delay #(
    .DATA_WIDTH(ACC_WIDTH),
    .DELAY_VALUE(PRE_ACC_DELAY)
) delay_pre_acc [2:0] (
    .clk(clk),
    .din({pow0_cast, pow1_cast, corr_re_cast}),
    .dout({pow0_delay, pow1_delay, corr_re_delay})
);


delay #(
    .DATA_WIDTH(1), 
    .DELAY_VALUE(PRE_ACC_DELAY)   //+1 for the casting
) delay_pre_acc_valid (
    .clk(clk),
    .din(cast_valid[0]),
    .dout(delay_valid)
);

//delay for the new_acc
wire new_acc_delay;

delay #(
    .DATA_WIDTH(1), 
    .DELAY_VALUE(1+PRE_ACC_DELAY)   //+1 for the casting
) delay_pre_acc_new_acc (
    .clk(clk),
    .din(new_acc_shift),
    .dout(new_acc_delay)
);

//accumulators

reg [$clog2(VECTOR_LEN/PARALLEL)-1:0] band_count=0;
always@(posedge clk)begin
    if(delay_valid)begin
        if(new_acc_delay)
            band_count <=0;
        else
            band_count <= band_count+1;
    end
end

wire [BANDS*DOUT_WIDTH-1:0] r11_out, r22_out, r12_out;
wire [BANDS-1:0] acc_valid;

localparam BAND_STEP = VECTOR_LEN/PARALLEL/BANDS;

genvar j;
generate 
for (i=0; i<BANDS; i=i+1)begin  :acc_loop
    wire valid_band;
    assign valid_band = delay_valid &(band_count>=i*BAND_STEP) & (band_count<(i+1)*BAND_STEP);
    
    //take care here!!! super double check!
    reg band_new_acc=0;
    always@(posedge clk)begin
        if(delay_valid & new_acc_delay)
            band_new_acc <= 1;
        else if(valid_band)
            band_new_acc <=0;
    end 


    signed_acc #(
        .DIN_WIDTH(ACC_WIDTH),
        .ACC_WIDTH(DOUT_WIDTH)
    ) r11_acc_inst(
        .clk(clk),
        .din(pow0_delay),
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
        .din(pow1_delay),
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
        .din(corr_re_delay),
        .din_valid(valid_band),
        .acc_done(band_new_acc),
        .dout(r12_out[DOUT_WIDTH*i+:DOUT_WIDTH]),
        .dout_valid()
    );

end
endgenerate

reg [$clog2(BAND_STEP)-1:0] inner_band_count=0;
reg [$clog2(BANDS)-1:0] band_number_r=0;
always@(posedge clk)begin
    if(delay_valid)begin
        if(new_acc_delay)begin
            band_number_r <=0;
            inner_band_count <= 0;
        end
        else begin
            if(inner_band_count==(BAND_STEP-1))begin
                inner_band_count <= 0;
                if(band_number_r==(BANDS-1))
                    band_number_r <=0;
                else
                    band_number_r <= band_number_r+1;
            end
            else
                inner_band_count <= inner_band_count+1;
        end
    end
end


reg signed [DOUT_WIDTH-1:0] r11_r=0, r22_r=0, r12_r=0;
reg dout_valid_r=0;
always@(posedge clk)begin
    dout_valid_r <= |acc_valid;//acc_valid[0];
    r11_r <= r11_out[band_number_r*DOUT_WIDTH+:DOUT_WIDTH];
    r22_r <= r22_out[band_number_r*DOUT_WIDTH+:DOUT_WIDTH];
    r12_r <= r12_out[band_number_r*DOUT_WIDTH+:DOUT_WIDTH];
end

assign band_number = band_number_r;
assign dout_valid = dout_valid_r;
assign r11 = r11_r;
assign r12 = r12_r;
assign r22 = r22_r;

endmodule

