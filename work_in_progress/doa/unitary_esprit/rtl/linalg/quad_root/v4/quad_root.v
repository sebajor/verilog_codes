`default_nettype none
`include "dsp48_mult.v"
`include "sqrt_lut.v"
`include "signed_cast.v"
/*
    typical solution of the quadratic equation
    x1 = (-b +sqrt(b**2-4ac))/2a
    x2 = (-b- sqrt(b**2-4ac))/2a
    
    for 2 antenna doa we have a =1 so we just have as input b,c 
    also we normalize the input ie c,b have ine int bit
*/

module quad_root #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    parameter SQRT_IN_WIDTH = 10,
    parameter SQRT_IN_PT = 7,       //the biggest value at the input square should be 4
    parameter SQRT_OUT_WIDTH = 8,
    parameter SQRT_OUT_PT = 5
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] b, c,
    input wire din_valid,

    output wire signed [SQRT_OUT_WIDTH-1:0] x1,x2,
    output wire dout_valid
);

localparam DIN_INT = DIN_WIDTH-DIN_POINT;

wire signed [2*DIN_WIDTH-1:0] b2;
wire b2_valid;
dsp48_mult #(
    .DIN1_WIDTH(DIN_WIDTH),
    .DIN2_WIDTH(DIN_WIDTH),
    .DOUT_WIDTH(2*DIN_WIDTH)
) b2_mult (
    .clk(clk),
    .rst(1'b0),
    .din1(b),
    .din2(b),
    .din_valid(din_valid),
    .dout(b2),
    .dout_valid(b2_valid)
);

//sync the rest of the signals
reg signed [DIN_WIDTH-1:0] c_r=0, c_rr=0, c_rrr=0;
reg signed [DIN_WIDTH-1:0] b_r=0, b_rr=0, b_rrr=0;
always@(posedge clk)begin
    c_r <= c;   c_rr<=c_r;  c_rrr<=c_rr;
    b_r <= b;   b_rr<=b_r;  b_rrr<=b_rr;
end

//4*c
reg signed [2*DIN_WIDTH-1:0] c4=0;
always@(posedge clk)begin
    c4 <= c_rrr<<<(DIN_POINT);  //we are going to set the point in 2DIN_PT-2
end

wire [2*DIN_WIDTH-1:0] b2_shift = b2>>>(2);   //align the points, check!

reg diff_valid=0;
reg signed [2*DIN_WIDTH-1:0] diff=0;
always@(posedge clk)begin
    diff_valid <= b2_valid;
    if(b2_valid)
        diff <= $signed(b2_shift)-$signed(c4);
end

//convert the data size to the sqrt input, we take the unsigned conversion
//if the data is negative we dont care, the complex root are wrong here
localparam DIFF_POINT = 2*DIN_POINT-(2);
localparam SQRT_IN_INT = SQRT_IN_WIDTH-SQRT_IN_PT;
reg [SQRT_IN_WIDTH-1:0] sqrt_in=0;
reg sqrt_in_valid =0;
always@(posedge clk)begin
    sqrt_in <= {diff[DIFF_POINT+:SQRT_IN_INT], diff[DIFF_POINT-1-:SQRT_IN_PT]};
    sqrt_in_valid <= diff_valid & ~diff[2*DIN_WIDTH-1]; //check if diff is negative
end

wire [SQRT_OUT_WIDTH-1:0] sqrt_dout;
wire sqrt_dout_valid;

sqrt_lut #(
    .DIN_WIDTH(SQRT_IN_WIDTH),
    .DIN_POINT(SQRT_IN_PT),
    .DOUT_WIDTH(SQRT_OUT_WIDTH),
    .DOUT_POINT(SQRT_OUT_PT),
    .SQRT_FILE("sqrt.hex")
) sqrt_inst (
    .clk(clk),
    .din(sqrt_in),
    .din_valid(sqrt_in_valid),
    .dout(sqrt_dout),
    .dout_valid(sqrt_dout_valid)
);

//convert b to SQRT_OUT_WIDTH
localparam SQRT_OUT_INT = SQRT_OUT_WIDTH-SQRT_OUT_PT;
wire signed [SQRT_OUT_WIDTH-1:0] b_resize;
signed_cast #(
    .PARALLEL(1),
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_INT(DIN_INT),
    .DOUT_WIDTH(SQRT_OUT_WIDTH),
    .DOUT_INT(SQRT_OUT_INT)
) b_cast (
    .clk(clk),
    .din(b_rrr),
    .din_valid(1'b1),
    .dout(b_resize),
    .dout_valid()
);



//delay fot b_resize to match sqrt_dout     check!
reg [3*SQRT_OUT_WIDTH-1:0] b_shift =0;
always@(posedge clk)begin
    b_shift <= {b_shift[2*SQRT_OUT_WIDTH-1:0], b_resize};
end


reg signed [SQRT_OUT_WIDTH-1:0] b_minus =0;
reg signed [SQRT_OUT_WIDTH-1:0] x1_r=0, x2_r=0;
reg dout_valid_r =0;

always@(posedge clk)begin
    b_minus <= ~b_shift[2*SQRT_OUT_WIDTH-1-:SQRT_OUT_WIDTH]+1'b1;   //inverting in 2 complement
    if(sqrt_dout_valid)begin
        x1_r <= $signed(b_minus)+$signed(sqrt_dout);
        x2_r <= $signed(b_minus)-$signed(sqrt_dout);
        dout_valid_r <= 1;
    end
    else begin
        dout_valid_r <=0;
    end
end

assign x1 = x1_r>>>1;
assign x2 = x2_r>>>1;
assign dout_valid = dout_valid_r;

endmodule




