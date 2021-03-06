`default_nettype none
`include "bram_infer.v"


module moving_average #(
    parameter DIN_WIDTH = 32,
    parameter DIN_POINT = 31,
    parameter WINDOW_LEN = 16,
    parameter DOUT_WIDTH = 32,
    parameter APPROX = "nearest"   //truncate, nearest
) (
    input wire clk,
    input wire rst,
    input wire signed [DIN_WIDTH-1:0] din,
    input wire din_valid,
    output wire signed [DOUT_WIDTH-1:0] dout,
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
///check timming!
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
always@(posedge clk)begin
    if(din_valid)begin
        comb_reg <= $signed(din)-$signed(diff_dly_out);
    end
    else 
        comb_reg <= comb_reg;
end


//integrator
reg din_valid_dly=0, dout_valid_r=0;
reg signed [DIN_WIDTH+$clog2(WINDOW_LEN)-1:0] integ=0; 
always@(posedge clk)begin
    din_valid_dly <= din_valid;
    if(rst)
        integ <= 0;
    else if(din_valid_dly)begin
        dout_valid_r <=1;
        integ <= $signed(comb_reg) + $signed(integ);
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
