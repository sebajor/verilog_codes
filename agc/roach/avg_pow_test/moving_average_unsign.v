`default_nettype none
`include "bram_infer.v"


module moving_average_unsign #(
    parameter DIN_WIDTH = 32,
    parameter DIN_POINT = 31,
    parameter WINDOW_LEN = 16,
    parameter DOUT_WIDTH = 32,
    parameter APPROX = "nearest"   //truncate, nearest
) (
    input wire clk,
    input wire rst,
    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,
    output wire [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);

reg [$clog2(WINDOW_LEN)-1:0] w_addr=0, r_addr=1;

always@(posedge clk)begin
    if(rst)begin
        w_addr <= 0;
        r_addr <= 1; 
    end
    else if(din_valid)begin
        w_addr <= w_addr+1;
        r_addr <= r_addr+1;
    end
    else begin
        w_addr <= w_addr;
        r_addr <= r_addr;
    end
end


wire signed [DIN_WIDTH-1:0] diff_dly_out;
///check timming! It has 2 cycles of delay
bram_infer #(
    .N_ADDR(WINDOW_LEN),
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


reg signed [DIN_WIDTH-1:0] comb_reg=0;
/*
always@(posedge clk)begin
    if(din_valid)begin
        comb_reg <= $signed(din)-$signed(diff_dly_out);
    end
    else 
        comb_reg <= comb_reg;
end
*/
reg valid_dly =0, valid_dly2=0;
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
        comb_reg <= din_dly2-prev_val2;
    end
    else 
        comb_reg <= comb_reg; 
end



//integrator
reg din_valid_dly=0, dout_valid_r=0;
reg signed [DIN_WIDTH+$clog2(WINDOW_LEN)-1:0] integ=0; 
always@(posedge clk)begin
    //din_valid_dly <= din_valid;
    din_valid_dly <= valid_dly2;
    if(rst)
        integ <= 0;
    else if(din_valid_dly)begin
        dout_valid_r <=1;
        integ <= comb_reg + integ;
    end
    else begin
        dout_valid_r <=0;
        integ <= integ;
    end
end

assign dout_valid = dout_valid_r;  //check!

//now we have to normalize the output
generate 
if(APPROX=="truncate")
    assign dout = integ[DIN_WIDTH+$clog2(WINDOW_LEN)-1-:DIN_WIDTH];
else if(APPROX=="nearest")
    assign dout = integ[$clog2(WINDOW_LEN)-1:0]>{1'b0,{(WINDOW_LEN-1){1'b1}}} ? (integ[DIN_WIDTH+$clog2(WINDOW_LEN)-1-:DIN_WIDTH]+1):
                            (integ[DIN_WIDTH+$clog2(WINDOW_LEN)-1-:DIN_WIDTH]);
else
    assign dout = integ[DIN_WIDTH+$clog2(WINDOW_LEN)-1-:DIN_WIDTH];
endgenerate

endmodule
