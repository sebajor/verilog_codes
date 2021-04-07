`default_nettype none
`include "bram_infer.v"

//the comb could 

module complex_comb #(
    parameter DIN_WIDTH = 8,
    parameter DIN_POINT = 7,
    parameter DELAY_LINE = 128
) (
    input wire clk,
    input wire rst,
    
    input wire [2*DIN_WIDTH-1:0] din,   //complex signal {re,im}
    input wire din_valid,

    output wire [2*(DIN_WIDTH+1)-1:0] dout,    //complex {re,im} full scale output
    output wire dout_valid
);


reg [$clog2(DELAY_LINE)-1:0] w_addr=0, r_addr=1;
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


wire [2*DIN_WIDTH-1:0] diff_dly_out;
///check timming!
bram_infer #(
    .N_ADDR(DELAY_LINE),
    .DATA_WIDTH(2*DIN_WIDTH)
) diff_dly (
    .clk(clk),
    .wen(din_valid),
    .ren(1'b1), //check
    .wadd(w_addr),
    .radd(r_addr),
    .win(din),
    .wout(diff_dly_out)
);

reg [2*DIN_WIDTH-1:0] comb_reg=0;
reg comb_valid =0;
always@(posedge clk)begin
    comb_valid <= din_valid;
    if(din_valid)begin
        comb_reg[0+:DIN_WIDTH] <= $signed(din[0+:DIN_WIDTH])-$signed(diff_dly_out[0+:DIN_WIDTH]);
        comb_reg[DIN_WIDTH+1+:DIN_WIDTH+1] <= $signed(din[DIN_WIDTH+:DIN_WIDTH])-$signed(diff_dly_out[DIN_WIDTH+:DIN_WIDTH]);
    end
    else begin
        comb_reg <= comb_reg;
    end
end

assign dout = comb_reg;
assign dout_valid = comb_valid;


endmodule
