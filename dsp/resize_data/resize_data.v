`default_nettype none

/*
*   Author:Sebastian Jorquera
*   Module to cast certain signal to another format.
*   The debug parameter allows you to check if there was an overflow/underflow
*   
*/

module resize_data #(
    parameter DIN_WIDTH = 18,
    parameter DIN_POINT = 16,
    parameter DATA_TYPE = "signed",  //signed or unsigned
    parameter PARALLEL = 4,
    parameter SHIFT = 6,    //negative >>, positive <<
    parameter DELAY = 0,
    parameter DOUT_WIDTH = 9,
    parameter DOUT_POINT = 8,
    parameter DEBUG = 1
) (
    input wire clk, 
    input wire [DIN_WIDTH*PARALLEL-1:0] din,
    input wire din_valid,
    input wire sync_in,

    output wire [DOUT_WIDTH*PARALLEL-1:0] dout,
    output wire dout_valid,
    output wire sync_out,
    output wire warning
);

wire [DIN_WIDTH*PARALLEL-1:0] din_shift;
wire [2*PARALLEL-1:0] shift_warn;


shift #(
    .DATA_WIDTH(DIN_WIDTH),
    .DATA_TYPE(DATA_TYPE),
    .SHIFT_VALUE(SHIFT),
    .ASYNC(0),
    .OVERFLOW_WARNING(DEBUG)
) input_shift [PARALLEL-1:0] (
    .clk(clk),
    .din(din),
    .dout(din_shift),
    .warning(shift_warn)
);
//delay the signals
reg din_valid_r=0;
reg sync_in_r=0, sync_delay=0;
always@(posedge clk)begin
    din_valid_r <= din_valid;
    sync_in_r <= sync_in;
    sync_delay <= sync_in_r;
end


wire valid_cast;
wire [DOUT_WIDTH*PARALLEL-1:0] din_cast;
wire [2*PARALLEL-1:0] cast_warning;
generate 
if(DATA_TYPE=="signed")begin
    signed_cast #(
        .DIN_WIDTH(DIN_WIDTH),
        .DIN_POINT(DIN_POINT),
        .DOUT_WIDTH(DOUT_WIDTH),
        .DOUT_POINT(DOUT_POINT),
        .OVERFLOW_WARNING(DEBUG)
    ) input_casting [PARALLEL-1:0] (
        .clk(clk), 
        .din(din_shift),
        .din_valid(din_valid_r),
        .dout(din_cast),
        .dout_valid(valid_cast),
        .warning(cast_warning)
    );
end
else begin
    unsign_cast #(
        .DIN_WIDTH(DIN_WIDTH),
        .DIN_POINT(DIN_POINT),
        .DOUT_WIDTH(DOUT_WIDTH),
        .DOUT_POINT(DOUT_POINT),
        .OVERFLOW_WARNING(DEBUG)
    ) input_casting [PARALLEL-1:0] (
        .clk(clk), 
        .din(din_shift),
        .din_valid(din_valid_r),
        .dout(din_cast),
        .dout_valid(valid_cast),
        .warning(cast_warning)
    );
end

if(DEBUG)begin
    assign warning = (|cast_warning) | (|shift_warn);

end
endgenerate

delay #(
    .DATA_WIDTH(PARALLEL*DOUT_WIDTH+2),
    .DELAY_VALUE(DELAY)
) delay_inst (
    .clk(clk),
    .din({din_cast, valid_cast, sync_delay}),
    .dout({dout, dout_valid, sync_out})
);


endmodule
