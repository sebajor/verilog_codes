`default_nettype none

/*
*   Author: Sebastian Jorquera
*
*
*/


module moving_average #(
    parameter DIN_WIDTH = 32,
    parameter DIN_POINT = 31,
    parameter WINDOW_LEN = 16,
    parameter DOUT_WIDTH = 32,
    parameter DATA_TYPE = "signed", //signed or unsigned
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


reg [DIN_WIDTH+1:0] comb_reg=0;
reg valid_dly =0, valid_dly2=0;
reg [DIN_WIDTH-1:0] din_dly=0, din_dly2=0;
reg [DIN_WIDTH-1:0] prev_val=0, prev_val2=0;
generate
    always@(posedge clk)begin
        valid_dly <= din_valid;
        valid_dly2 <= valid_dly;
        din_dly <= din;
        din_dly2 <= din_dly;
        if(valid_dly2)begin
            prev_val <= diff_dly_out;
            prev_val2 <= prev_val;
            if(DATA_TYPE=="signed")
                comb_reg <= $signed(din_dly2)-$signed(prev_val2);
            else
                comb_reg <=  din_dly2-prev_val2;
        end
        else 
            comb_reg <= comb_reg; 
    end
endgenerate



//integrator
reg din_valid_dly=0, dout_valid_r=0;
reg [DIN_WIDTH+$clog2(WINDOW_LEN)-1:0] integ=0; 
generate 
    always@(posedge clk)begin
        //din_valid_dly <= din_valid;
        din_valid_dly <= valid_dly2;
        if(rst)
            integ <= 0;
        else if(din_valid_dly)begin
            dout_valid_r <=1;
            if(DATA_TYPE=="signed")
                integ <= $signed(comb_reg) + $signed(integ);
            else
                integ <= comb_reg + integ;
        end
        else begin
            dout_valid_r <=0;
            integ <= integ;
        end
    end
endgenerate

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
