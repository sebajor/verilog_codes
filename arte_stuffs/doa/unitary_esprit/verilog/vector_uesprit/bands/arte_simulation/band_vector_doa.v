`default_nettype none

module band_vector_doa #(
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
    parameter ACC_DOUT = 32,
    //linear algebra parameters
    parameter LA_DELAY_IN = 2,
    parameter LA_DIN_WIDTH = 16,
    parameter LA_DIN_POINT = 10,
    parameter SQRT_WIDTH = 16,
    parameter SQRT_POINT = 8,
    parameter DOUT_WIDTH = 16,
    parameter DOUT_POINT = 13,
    parameter FIFO_DEPTH = 8
) (
    
    input wire clk,
    input wire [PARALLEL*DIN_WIDTH-1:0] din1_re, din1_im,
    input wire [PARALLEL*DIN_WIDTH-1:0] din2_re, din2_im,
    input wire din_valid,
    input wire new_acc,     //this comes previous the first channel

    output wire signed [DOUT_WIDTH-1:0] lamb1, lamb2,
    output wire signed [DOUT_WIDTH-1:0] eigen1_y, eigen2_y, eigen_x,
    //the correct eigen value is eigen_y/eigen_x, but the output of this
    //module goes into a arctan so we are happy with that :)
    output wire dout_valid,
    output wire dout_error,
    output wire [$clog2(BANDS)-1:0] band_out,
    output wire fifo_full

);

wire signed [ACC_DOUT-1:0] r11,r22,r12;
wire acc_valid;
wire [$clog2(BANDS)-1:0] acc_band_out;

band_doa_no_la #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .PARALLEL(PARALLEL),
    .VECTOR_LEN(VECTOR_LEN),
    .BANDS(BANDS),
    .PRE_ACC_DELAY(PRE_ACC_DELAY),
    .PRE_ACC_SHIFT(PRE_ACC_SHIFT),
    .ACC_WIDTH(ACC_WIDTH),
    .ACC_POINT(ACC_POINT),
    .DOUT_WIDTH(ACC_DOUT)
) band_doa_no_la_inst (
    .clk(clk),
    .din1_re(din1_re),
    .din1_im(din1_im),
    .din2_re(din2_re),
    .din2_im(din2_im),
    .din_valid(din_valid),
    .new_acc(new_acc),
    .r11(r11),
    .r22(r22),
    .r12(r12),
    .dout_valid(acc_valid),
    .band_number(acc_band_out)
);
//delay to match the cast
reg [$clog2(BANDS)-1:0] acc_band_out_r=0;
always@(posedge clk)begin
    acc_band_out_r <= acc_band_out;
end

wire signed [ACC_DOUT-1:0] r11_shift, r12_shift, r22_shift;
shift #(
    .DATA_WIDTH(ACC_DOUT),
    .DATA_TYPE("signed"), //"signed" or "unsigned"
    .SHIFT_VALUE(PRE_ACC_SHIFT),      //positive <<, negative >>
    .ASYNC(1)             // 
) shift_pre_acc_inst [2:0] (
    .clk(clk),
    .din({r11,r12,r22}),
    .dout({r11_shift, r12_shift, r22_shift})
);





wire signed [LA_DIN_WIDTH-1:0] r11_cast, r12_cast, r22_cast;
wire acc_valid_r;

signed_cast #(
    .DIN_WIDTH(ACC_DOUT),
    .DIN_POINT(ACC_POINT),
    .DOUT_WIDTH(LA_DIN_WIDTH),
    .DOUT_POINT(LA_DIN_POINT)
) acc_cast_inst [2:0] (
    .clk(clk), 
    .din({r11_shift,r12_shift,r22_shift}),
    .din_valid(acc_valid),
    .dout({r11_cast, r12_cast, r22_cast}),
    .dout_valid(acc_valid_r)
);

wire [LA_DIN_WIDTH-1:0] r11_data, r12_data, r22_data;
wire [$clog2(BANDS)-1:0] la_band_in;
wire la_in_valid;

delay #(
    .DATA_WIDTH(3*LA_DIN_WIDTH+$clog2(BANDS)+1),
    .DELAY_VALUE(LA_DELAY_IN)
) delay_inst (
    .clk(clk),
    .din({r11_cast,r12_cast,r22_cast,acc_band_out_r,acc_valid_r}),
    .dout({r11_data,r12_data,r22_data,la_band_in, la_in_valid})
);




quad_eigen_iterative #(
    .DIN_WIDTH(LA_DIN_WIDTH),
    .DIN_POINT(LA_DIN_POINT),
    .SQRT_WIDTH(SQRT_WIDTH),
    .SQRT_POINT(SQRT_POINT),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT),
    .BANDS(BANDS),
    .FIFO_DEPTH(FIFO_DEPTH)
) quad_eigen_iterative_inst (
    .clk(clk),
    .r11(r11_data),
    .r22(r22_data),
    .r12(r12_data),
    .din_valid(la_in_valid),
    .band_in(la_band_in),
    .lamb1(lamb1),
    .lamb2(lamb2),
    .eigen1_y(eigen1_y),
    .eigen2_y(eigen2_y),
    .eigen_x(eigen_x),
    .dout_valid(dout_valid),
    .dout_error(dout_error),
    .band_out(band_out),
    .fifo_full(fifo_full)
);

endmodule
