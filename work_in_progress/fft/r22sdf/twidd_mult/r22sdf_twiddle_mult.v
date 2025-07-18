`default_nettype none

/*
*   Author: sebastian jorquera
*   The twiddle multiplication its divided in 4 different situation
*   W_n^0, W_n^(2*i), W_n^i, W_n^(3*i) with i belongs to (0, N/4-1)
*   Since there are several trivial multiplications by 1 this module only 
*   store the non trivial twiddle factors (maybe you can also use some 
*   geometrical properties but that makes the addressing more complex, so 
*   fuck it)
*/

module r22sdf_twiddle_mult #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    parameter FFT_SIZE = 16,
    parameter TWIDDLE_WIDTH = 16,
    parameter TWIDDLE_POINT = 14,
    parameter TWIDDLE_FILE = "twiddles/stage16_16_14",
    parameter DEBUG = 0
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din_re, din_im, 
    input wire din_valid,
    input wire rst,

    output wire signed [DIN_WIDTH-1:0] dout_re, dout_im,
    output wire dout_valid
);

reg [$clog2(FFT_SIZE)-1:0] counter = 0;

always@(posedge clk)begin
    if(rst)
        counter <= 0;
    else if(din_valid)
        counter <= counter+1;
end

//the first quarter of the data is 1 and just pass
//the first sample of each quarter is also 1
reg state = 0;  //0= pass the input
                //1= multiply by the twid

always@(posedge clk)begin
    if(rst)
        state = 0;
    else begin
        if(counter == FFT_SIZE/4)
            state <= 1;
        else if(counter == FFT_SIZE/2-1)
            state <=0;
        else if(counter == FFT_SIZE/2)
            state <= 1;
        else if(counter == 3*FFT_SIZE/4-1)
            state <= 0;
        else if(counter == 3*FFT_SIZE/4)
            state <= 1;
        else if(&counter)
            state <=0;
    end
end

localparam NON_TRIVIAL_TWIDDLES = 3*FFT_SIZE/4-3;

reg [$clog2(NON_TRIVIAL_TWIDDLES)-1:0] rom_addr =0;
wire [TWIDDLE_WIDTH-1:0] twidd_re, twidd_im;
reg signed [DIN_WIDTH-1:0] din_re_delay=0, din_im_delay=0;
reg din_valid_delay=0;
reg state_delay=0;


always@(posedge clk)begin
    din_re_delay <= din_re;
    din_im_delay <= din_im;
    din_valid_delay <= din_valid;
    state_delay <= state;
    if(rst)
        rom_addr <= 0;
    else if(state)begin
        if(rom_addr==(NON_TRIVIAL_TWIDDLES-1))
            rom_addr <= 0;
        else
            rom_addr <= rom_addr+1;
    end
end



rom #(
    .N_ADDR(NON_TRIVIAL_TWIDDLES),
    .DATA_WIDTH(2*TWIDDLE_WIDTH),
    .INIT_VALS(TWIDDLE_FILE)
) rom_inst_re (
    .clk(clk),
    .ren(1'b1),
    .radd(rom_addr),
    .wout({twidd_re, twidd_im})
);


//this takes 6 cycles
wire signed [DIN_WIDTH+TWIDDLE_WIDTH:0] mult_re, mult_im;
wire mult_valid;
complex_mult #(
    .DIN1_WIDTH(DIN_WIDTH),
    .DIN2_WIDTH(TWIDDLE_WIDTH)
) complex_mult_inst (
    .clk(clk),
    .din1_re(din_re_delay),
    .din1_im(din_im_delay),
    .din2_re(twidd_re),
    .din2_im(twidd_im),
    .din_valid(din_valid_delay),
    .dout_re(mult_re),
    .dout_im(mult_im),
    .dout_valid(mult_valid)
);

wire signed [DIN_WIDTH-1:0] mult_re_cast, mult_im_cast;
wire cast_valid;
wire [1:0] debug;

signed_cast #(
    .DIN_WIDTH(DIN_WIDTH+TWIDDLE_WIDTH+1),
    .DIN_POINT(DIN_POINT+TWIDDLE_POINT),
    .DOUT_WIDTH(DIN_WIDTH),
    .DOUT_POINT(DIN_POINT),
    .OVERFLOW_WARNING(DEBUG)
) cast_inst [1:0] (
    .clk(clk), 
    .din({mult_re, mult_im}),
    .din_valid(mult_valid),
    .dout({mult_re_cast, mult_im_cast}),
    .dout_valid(cast_valid),
    .warning(debug)
);

//now we delay the input data and the state to take the decision of which one output

wire signed [DIN_WIDTH-1:0] din_re_r, din_im_r;
wire state_r;
delay #(
    .DATA_WIDTH(2*DIN_WIDTH+1),
    .DELAY_VALUE(7)
) delay_inst  (
    .clk(clk),
    .din({din_re_delay, din_im_delay, state_delay}),
    .dout({din_re_r, din_im_r, state_r})
);

assign dout_re = state_r? mult_re_cast:din_re_r;
assign dout_im = state_r? mult_im_cast:din_im_r;
assign dout_valid = cast_valid;





endmodule
