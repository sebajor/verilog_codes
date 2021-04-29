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
    parameter SQRT_IN_WIDTH = 10,
    parameter SQRT_OUT_WIDTH = 8,
    parameter SQRT_OUT_PT = 6
) (
    input wire clk, 
    input wire signed [DIN_WIDTH-1:0] b, c,
    input wire din_valid,

    output wire signed [SQRT_OUT_WIDTH:0] x1,x2,
    output wire dout_valid
);

localparam DIN_POINT = DIN_WIDTH-1;

//b^2
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

/*To have a real sqrt we need that b^2 > 4c, if the input is normalize
ie in (0,1) then c should be at most 0.25 otherwise the output would be 
complex
*/
localparam DIN_INT = DIN_WIDTH-DIN_POINT;
localparam MAX_C = {{3'b001}, {(DIN_POINT-3){1'b0}}};
reg signed [2*DIN_WIDTH-1:0] c4=0;
reg complex_out=0;
always@(posedge clk)begin
    c4<= c_rrr<<<(DIN_POINT+2);
    if(c_rrr>MAX_C)
        complex_out <=1;
    else 
        complex_out <=0;
end

//c4 has the point 2*DIN_PT 


//b**2-4ac
reg diff_valid =0, complex_out_r=0;
reg signed [2*DIN_WIDTH-1:0] diff=0;
always@(posedge clk)begin
    diff_valid <= b2_valid;
    complex_out_r <= complex_out;
    if(b2_valid)begin
        diff <= $signed(b2)-$signed(c4);
    end
end


//if its positive transform the data is easy piece
//here we take the sign and the most significant of the fractional part
reg [SQRT_IN_WIDTH-1:0] sqrt_in=0;
reg sqrt_in_valid=0;
always@(posedge clk)begin
    sqrt_in <=  {diff[2*DIN_WIDTH-1], diff[2*DIN_POINT-1-:SQRT_IN_WIDTH-1]};
    //only allows the sqrt computation when diff is posive and there wasnt an overflow in 4c
    sqrt_in_valid <= diff_valid & ~diff[2*DIN_WIDTH-1] & ~complex_out_r;
end

wire [SQRT_OUT_WIDTH-1:0] sqrt_dout;
wire sqrt_dout_valid;

sqrt_lut #(
    .DIN_WIDTH(SQRT_IN_WIDTH),
    .DIN_POINT(SQRT_IN_WIDTH-1),
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
reg signed [SQRT_OUT_WIDTH:0] x1_r=0, x2_r=0;
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
