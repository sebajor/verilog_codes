`default_nettype none

/*
*   This is just to test the how the whole system works
*/

module arte_accumulator #(
    parameter DIN_WIDTH = 32,
    parameter DIN_POINT = 20,
    parameter FFT_CHANNEL =2048,
    parameter PARALLEL = 4,
    parameter INPUT_DELAY = 0,
    parameter OUTPUT_DELAY =0,
    parameter DOUT_WIDTH = 32,
    parameter DEBUG=1

)(
    input wire clk,
    input wire cnt_rst,

    input wire sync_in,
    input wire [PARALLEL*DIN_WIDTH-1:0] power,

    input wire [31:0] acc_len,

    output wire [DOUT_WIDTH-1:0] dout,
    output wire dout_valid

);

wire [DIN_WIDTH+$clog2(PARALLEL)+1:0] dout_rebin;
wire rebin_valid;

arte_rebin #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .FFT_CHANNEL(FFT_CHANNEL),
    .PARALLEL(PARALLEL),
    .INPUT_DELAY(INPUT_DELAY),
    .OUTPUT_DELAY(OUTPUT_DELAY),
    .DEBUG(DEBUG)
) arte_rebin (
    .clk(clk),
    .cnt_rst(cnt_rst),
    .sync_in(sync_in),
    .power_resize(power),
    .dout(dout_rebin),
    .dout_valid(rebin_valid)
);


wire new_acc;
acc_control #(
    .CHANNEL_ADDR($clog2(FFT_CHANNEL)-$clog2(PARALLEL))
) acc_control_inst (
    .clk(clk),
    .ce(),
    .sync_in(rebin_valid),
    .acc_len(acc_len),
    .rst(cnt_rst),
    .new_acc(new_acc)
);

//check!
wire [DIN_WIDTH+$clog2(PARALLEL)+1:0] dout_rebin_r;
wire rebin_valid_r;
delay #(
    .DATA_WIDTH(DIN_WIDTH+$clog2(PARALLEL)+3),
    .DELAY_VALUE(2)
)rebin_delay (
    .clk(clk),
    .din({dout_rebin, rebin_valid}),
    .dout({dout_rebin_r, rebin_valid_r})
);

reg [31:0] debug_counter=0;
always@(posedge clk)begin
    if(new_acc)
        debug_counter <= 0;
    else
        debug_counter <= debug_counter+1;
end
reg [5:0] addr_counter=0;
always@(posedge clk)begin
    if(rebin_valid_r)
        addr_counter <= addr_counter+1;

end

vector_accumulator #(
    .DIN_WIDTH(DIN_WIDTH+$clog2(PARALLEL)+2),
    .VECTOR_LEN(FFT_CHANNEL/4/8),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DATA_TYPE("unsigned")
) vector_acc_inst (
    .clk(clk),
    .new_acc(new_acc),     //new accumulation, set it previous the first sample of the frame
    .din(dout_rebin_r),
    .din_valid(rebin_valid_r),
    .dout(dout),
    .dout_valid(dout_valid)
);

endmodule
