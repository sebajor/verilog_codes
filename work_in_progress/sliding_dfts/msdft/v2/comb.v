`default_nettype none
`include "bram_infer.v"

module comb #(
    parameter DIN_WIDTH = 16,
    parameter DELAY_LINE = 16,
    parameter DOUT_WIDTH = DIN_WIDTH+1
) (
    input wire clk,
    input wire rst,
    input wire signed [DIN_WIDTH-1:0] din,
    input wire din_valid,
    input wire [31:0] delay_line,
    output wire signed [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);

reg [$clog2(DELAY_LINE)-1:0] w_addr=0, r_addr=1;

always@(posedge clk)begin
    if(rst)begin
        w_addr <= 0;
        r_addr <= 1;
    end
    else if(din_valid)begin
        if(w_addr==delay_line)
            w_addr<=0;
        if(r_addr==delay_line)
            r_addr<=0;
        else begin
            w_addr <= w_addr+1;
            r_addr <= r_addr+1;
        end
    end
    else begin
        w_addr <= w_addr;
        r_addr <= r_addr;
    end
end

wire signed [DIN_WIDTH-1:0] diff_dly_out;
///check timming! It has 2 cycles of delay
bram_infer #(
    .N_ADDR(DELAY_LINE),
    .DATA_WIDTH(DIN_WIDTH)
) diff_dly (
    .clk(clk),
    .wen(din_valid),
    .ren(1'b1), //check
    .wadd(w_addr),
    .radd(r_addr),
    .win(din),
    .wout(diff_dly_out)
);

reg signed [DOUT_WIDTH:0] comb_reg=0;

reg valid_dly =0, valid_dly2=0, dout_valid_r=0;
reg [DIN_WIDTH-1:0] din_dly=0, din_dly2=0;
reg [DIN_WIDTH-1:0] prev_val=0, prev_val2=0;
always@(posedge clk)begin
    valid_dly <= din_valid;
    valid_dly2 <= valid_dly;
    din_dly <= din;
    din_dly2 <= din_dly;
    if(valid_dly2)begin
        prev_val <= diff_dly_out;
        prev_val2 <= prev_val;
        comb_reg <= $signed(din_dly2)-$signed(prev_val2);
        dout_valid_r <= 1;
    end
    else begin
        comb_reg <= comb_reg; 
        dout_valid_r <= dout_valid;
    end
end

assign dout = comb_reg;
assign dout_valid = dout_valid_r;




endmodule
