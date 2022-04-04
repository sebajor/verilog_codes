`default_nettype none
/*
    Compare two signed inputs and determine the optimal shifting to
   use in best way the DIN_WIDTH bits.
   Like in the arctang we manage to just use the first quadrant the
   input are always unsigned :)
*/


module autoscale #(
    parameter MAX_SHIFT = 10,
    parameter MIN_SHIFT = 3,
    parameter DIN_WIDTH = 32
) (
    input wire clk,
    input wire [DIN_WIDTH-1:0] din1, din2,
    input wire din_valid,
    output wire [DIN_WIDTH-1:0] dout1, dout2,
    output wire dout_valid,
    output wire [$clog2(DIN_WIDTH)-1:0] shift_value
);

reg [DIN_WIDTH-1:0] index=0, din1_r=0, din2_r=0;
reg din_valid_r=0;

always@(posedge clk)begin
    din1_r <= din1; din2_r <= din2;
    index <= din1 | din2;
    din_valid_r <= din_valid;
end

//now we nee to found the first appearence of a 1 in index
//priority encoder
wire [$clog2(DIN_WIDTH)-1:0] first_one;

first_one_finder #(
    .DIN_WIDTH(DIN_WIDTH)
)first_one_finder_inst (
    .clk(clk),
    .din(index),
    .din_valid(1'b1),
    .dout(first_one)
);

reg valid_r=0;
reg [DIN_WIDTH-1:0] din1_rr=0, din2_rr=0;
always@(posedge clk)begin
    din1_rr <= din1_r; din2_rr <= din2_r;
    valid_r <= din_valid_r;
end

reg [$clog2(DIN_WIDTH)-1:0] debug=0;

//calculate the shift
reg [$clog2(DIN_WIDTH)-1:0] shift=0;
reg valid_rr=0;
reg [DIN_WIDTH-1:0] din1_rrr=0, din2_rrr=0;
always@(posedge clk)begin
    debug <= first_one;
    shift <= (DIN_WIDTH-3)-first_one; //DIN_WIDTH-1-first_one;    //check!
    valid_rr <= valid_r;
    din1_rrr <= din1_rr;    din2_rrr <= din2_rr;
end

//shift the data the rigth amount 
reg dout_valid_r=0;
reg [DIN_WIDTH-1:0] dout1_r=0, dout2_r=0;
always@(posedge clk)begin
    dout_valid_r <= valid_rr;
    if(shift>MAX_SHIFT)begin
        dout1_r <= din1_rrr<<(MAX_SHIFT);
        dout2_r <= din2_rrr<<(MAX_SHIFT);
    end
    else if(shift < MIN_SHIFT)begin
        dout1_r <= din1_rrr;
        dout2_r <= din2_rrr;
    end
    else begin
        dout1_r <= din1_rrr<<(shift);
        dout2_r <= din2_rrr<<(shift);
    end
end

reg [$clog2(DIN_WIDTH)-1:0] shift_r=0;
always@(posedge clk)begin
    if(shift>MAX_SHIFT)
        shift_r <= MAX_SHIFT;
    else if(shift<MIN_SHIFT)
        shift_r <= MIN_SHIFT;
    else
        shift_r <= shift;
end

assign shift_value = shift_r;
assign dout1 = dout1_r;
assign dout2 = dout2_r;
assign dout_valid = dout_valid_r;

endmodule
