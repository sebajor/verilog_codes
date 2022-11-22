`default_nettype none

/*
*   Author: Sebastian Jorquera
*   
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
    parameter DOUT_POINT = 2*DIN_POINT,
    parameter DEBUG = 0
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din_re, din_im,
    input wire din_valid,
    input wire sync_in,
    input wire [31:0] acc_len,
    input wire cnt_rst,

    output wire [DOUT_WIDTH-1:0] dout,
    output wire dout_valid,
    output wire [$clog2(VECTOR_LEN)-1:0] dout_addr,
    output wire ovf_flag
);

reg din_valid_r=0;
reg signed [DIN_WIDTH-1:0] din_re_r=0, din_im_r=0;
reg sync_in_r=0;
always@(posedge clk)begin
    din_re_r <= din_re;
    din_im_r <= din_im;
    sync_in_r <= sync_in;
    if(cnt_rst)
        din_valid_r<=0;
    else if(sync_in)
        din_valid_r <=1;
end


//calcula the power of the complex data
wire [POWER_DOUT:0] power_dout;
wire power_dout_valid;

complex_power #(
    .DIN_WIDTH(DIN_WIDTH)
) complex_power_inst (
    .clk(clk),
    .din_re(din_re),
    .din_im(din_im),
    .din_valid(din_valid_r),
    .dout(power_dout),
    .dout_valid(power_dout_valid)
);

//delay to match the valid signal
wire sync_pow;
delay #(
    .DATA_WIDTH(1),
    .DELAY_VALUE(4)
) delay_power (
    .clk(clk),
    .din(sync_in_r),
    .dout(sync_pow)
);



//resize the output
wire [ACC_DIN_WIDTH-1:0] acc_in;
wire acc_sync_in;
wire power_cast_warning;
wire power_cast_valid;

resize_data #(
    .DIN_WIDTH(POWER_DOUT+1),
    .DIN_POINT(2*DIN_POINT),
    .DATA_TYPE("unsigned"),
    .PARALLEL(1),
    .SHIFT(POWER_SHIFT),
    .DELAY(POWER_DELAY),
    .DOUT_WIDTH(ACC_DIN_WIDTH),
    .DOUT_POINT(ACC_DIN_POINT),
    .DEBUG(DEBUG)
) resize_power (
    .clk(clk), 
    .din(power_dout),
    .din_valid(power_dout_valid),
    .sync_in(sync_pow),
    .dout(acc_in),
    .dout_valid(power_cast_valid),
    .sync_out(acc_sync_in),
    .warning(power_cast_warning)
);

//accumulation control signal
wire new_acc;

reg [31:0] frame_counter=0;
reg frame_en=0;
always@(posedge clk)begin
    if(cnt_rst)
        frame_en<=0;
    else if(acc_sync_in)
        frame_en <= 1;
end

always@(posedge clk)begin
    if(cnt_rst)
        frame_counter <=0;
    else if(frame_en)begin
        if(frame_counter == (acc_len<<$clog2(VECTOR_LEN))-1)
            frame_counter <=0;
        else
            frame_counter <= frame_counter+1;
    end
end

assign new_acc = (frame_counter == (acc_len<<$clog2(VECTOR_LEN))-1);


/*
acc_control #(
    .CHANNEL_ADDR($clog2(VECTOR_LEN))
) acc_control_inst (
    .clk(clk),
    .sync_in(acc_sync_in),
    .acc_len(acc_len),
    .rst(cnt_rst),
    .new_acc(new_acc)
);
*/

//check timing!!
wire [DOUT_WIDTH-1:0] vector_out;
wire vector_out_valid;

vector_accumulator #(
    .DIN_WIDTH(ACC_DIN_WIDTH),
    .VECTOR_LEN(VECTOR_LEN),
    .DOUT_WIDTH(ACC_DOUT_WIDTH),
    .DATA_TYPE("unsigned")
) vector_accumulator_inst (
    .clk(clk),
    .new_acc(new_acc),     //new accumulation, set it previous the first sample of the frame
    .din(acc_in),
    .din_valid(power_cast_valid),
    .dout(vector_out),
    .dout_valid(vector_out_valid)
);


//counter
reg [$clog2(VECTOR_LEN)-1:0] addr_counter=0;
always@(posedge clk)begin
    if(new_acc)
        addr_counter <= 0;//{($clog2(VECTOR_LEN)){1'b1}};
    else if(vector_out_valid)
        addr_counter <= addr_counter+1;
end

assign dout = vector_out;
assign dout_valid = vector_out_valid;
assign dout_addr = addr_counter;

assign ovf_flag = power_cast_warning;

endmodule
