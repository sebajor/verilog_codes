//`default_nettype none 
//`include "bram_infer.v"

module dedispersor_block #(
    parameter DELAY_LINE = 32,
    parameter DIN_WIDTH = 32
) (
    input wire clk,
    input wire ce,
    input wire rst,
    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,
    output wire [DIN_WIDTH-1:0] dout,
    output wire dout_valid
);

reg [31:0] asd = DELAY_LINE;

reg [$clog2(DELAY_LINE)-1:0] counter_r=1, counter_w=0;

//write address
always@(posedge clk)begin
    if(rst)
        counter_w <=0;
    else if(din_valid)begin
        if(counter_w==DELAY_LINE-1)
            counter_w <= 0;
        else
            counter_w <= counter_w+1;
    end
    else
        counter_w <= counter_w;
end
//read address
always@(posedge clk)begin
    if(rst)
        counter_r <= 1;
    else if(din_valid)begin
        if(counter_r==DELAY_LINE-1)
            counter_r <= 0;
        else
            counter_r <= counter_r+1;
    end
    else
        counter_r <= counter_r;
end


bram_infer #(
    .N_ADDR(DELAY_LINE),
    .DATA_WIDTH(DIN_WIDTH)
) bram_infer_inst (
    .clk(clk),
    .wen(din_valid),
    .ren(din_valid),
    .wadd(counter_w),
    .radd(counter_r),
    .win(din),
    .wout(dout)
);

//delay one cycle the valid signal
reg dout_valid_r = 0;
assign dout_valid = dout_valid_r;
always@(posedge clk)begin
    if(rst)
        dout_valid_r <=0;
    else
        dout_valid_r <= din_valid;
end



endmodule 
