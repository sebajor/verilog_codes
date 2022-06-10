`default_nettype none

/*
* Author: Sebastian Jorquera
* Programmable comb filter.
* The delay line input sets how many cycles the input signal is saved.
* Comb filter = x(0)-x(L-1); L = delay line
*/

module comb #(
    parameter DIN_WIDTH = 8,
    parameter DELAY_LINE = 16,
    parameter DOUT_WIDHT = 9
) (
    input wire clk,
    input wire rst,
    input wire signed [DIN_WIDTH-1:0] din,
    input wire din_valid,
    input wire [31:0] delay_line,
    output wire signed [DOUT_WIDHT-1:0] dout,
    output wire dout_valid
);

reg [31:0] delay_line_r=(2**$clog2(DELAY_LINE)-1);
always@(posedge clk)begin
    delay_line_r <= delay_line;
end


reg [$clog2(DELAY_LINE)-1:0] w_addr=0, r_addr=1;

//write pointer
always@(posedge clk)begin
    if(rst)begin
        w_addr <= 0;
    end
    else if(din_valid)begin
        if(w_addr==delay_line_r)
            w_addr <= 0;
        else 
            w_addr <= w_addr+1;
    end
    else begin
        w_addr <= w_addr;
    end
end

//read pointer
always@(posedge clk)begin
    if(rst)begin
        r_addr <= 1;
    end
    else if(din_valid)begin
        if(r_addr==delay_line_r)
            r_addr <= 0;
        else
            r_addr <= r_addr+1;
    end
    else
        r_addr <= r_addr;
end


wire signed [DIN_WIDTH-1:0] diff_dly_out;
bram_infer #(
    .N_ADDR(DELAY_LINE),
    .DATA_WIDTH(DIN_WIDTH),
    .INIT_VALS()
) bram_inst (
    .clk(clk),
    .wen(din_valid),
    .ren(1'b1),
    .wadd(w_addr),
    .radd(r_addr),
    .win(din),
    .wout(diff_dly_out)
);

reg signed [DOUT_WIDHT-1:0] comb_reg=0;

reg [2:0] valid_dly =0; // valid_dly2=0;
reg [DIN_WIDTH-1:0] din_dly=0, din_dly2=0;
reg [DIN_WIDTH-1:0] prev_val=0, prev_val2=0;
always@(posedge clk)begin
    valid_dly <= {valid_dly[1:0],din_valid&~rst};
    //valid_dly <= din_valid;
    //valid_dly2 <= valid_dly;
    din_dly <=din;
    din_dly2 <= din_dly;
    if(valid_dly[1])begin
        prev_val <= diff_dly_out;
        prev_val2 <= prev_val;
        comb_reg <= $signed(din_dly2)-$signed(prev_val2);
    end
    else 
        comb_reg <= comb_reg;
end

assign dout = comb_reg;
assign dout_valid = valid_dly[2];

endmodule
