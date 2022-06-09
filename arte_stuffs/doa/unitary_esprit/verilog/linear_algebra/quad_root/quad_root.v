`default_nettype none

/*
*   Author: Sebastian Jorquera
*
*    typical solution of the quadratic equation
*    x1 = (-b +sqrt(b**2-4ac))/2a
*    x2 = (-b- sqrt(b**2-4ac))/2a
*    
*    for 2 antenna doa we have a =1 so we just have as input b,c 
*    also we normalize the input ie c,b have ine int bit
*    
*    Look out the sqrt_in_width and sqrt_out_width.. the square root
*    is calculated using a rom, so the size matter!
*
*/

module quad_root #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    parameter SQRT_IN_WIDTH = 10,
    parameter SQRT_IN_POINT = 7,
    parameter DOUT_WIDTH = 16,
    parameter DOUT_POINT = 13,
    parameter SQRT_MEM_FILE = "sqrt.mem"
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] b,c,
    input wire din_valid,

    output wire signed [DOUT_WIDTH-1:0] x1,x2,
    output wire dout_valid,
    output wire dout_error
);

wire signed [2*DIN_WIDTH-1:0] b2;
wire b2_valid;

dsp48_mult #(
    .DIN1_WIDTH(DIN_WIDTH),
    .DIN2_WIDTH(DIN_WIDTH),
    .DOUT_WIDTH(2*DIN_WIDTH)
) mult_inst (
    .clk(clk),
    .rst(1'b0),
    .din1(b),
    .din2(b),
    .din_valid(din_valid),
    .dout(b2),
    .dout_valid(b2_valid)
);

//sync the rest of the signals
reg signed [3*DIN_WIDTH-1:0] c_r=0, b_r=0;
always@(posedge clk)begin
    c_r <= {c_r[2*DIN_WIDTH-1:0], c};
    b_r <= {b_r[2*DIN_WIDTH-1:0], b};
end

//4*c
reg signed [2*DIN_WIDTH-1:0] c4=0;
always@(posedge clk)begin
    c4 <= $signed(c_r[2*DIN_WIDTH+:DIN_WIDTH])<<<(DIN_POINT);    //we set the point in 2*DIN_PT-2
end

//align the point
wire signed [2*DIN_WIDTH-1:0] b2_shift = b2>>>2; 

//difference between b**2-4ac
reg diff_valid=0;
reg signed [2*DIN_WIDTH-1:0] diff=0;
always@(posedge clk)begin
    diff_valid <= b2_valid;
    if(b2_valid)
        diff <= $signed(b2_shift)-$signed(c4);
end

//convert the data to sqrt input
localparam DIFF_POINT = 2*DIN_POINT-2;
wire [SQRT_IN_WIDTH-1:0] sqrt_in;
wire sqrt_in_valid;


signed_cast #(
    .DIN_WIDTH(2*DIN_WIDTH),
    .DIN_POINT(DIFF_POINT),
    .DOUT_WIDTH(SQRT_IN_WIDTH),
    .DOUT_POINT(SQRT_IN_POINT)
) sqrt_in_cast (
    .clk(clk), 
    .din(diff),
    .din_valid(diff_valid),
    .dout(sqrt_in),
    .dout_valid(sqrt_in_valid)
);


wire [DOUT_WIDTH-1:0] sqrt_dout;

sqrt_lut #(
    .DIN_WIDTH(SQRT_IN_WIDTH),
    .DIN_POINT(SQRT_IN_POINT),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT),
    .SQRT_FILE(SQRT_MEM_FILE)
) sqrt_inst (
    .clk(clk),
    .din(sqrt_in),
    .din_valid(sqrt_in_valid & ~sqrt_in[SQRT_IN_WIDTH-1]),
    .dout(sqrt_dout),
    .dout_valid()   //replaced by a delay, so the error is also taken in account
);

reg sqrt_dout_valid=0;
always@(posedge clk)
    sqrt_dout_valid <= sqrt_in_valid;

//check if the input of the sqrt is positive
reg error=0;
always@(posedge clk)begin
    if(sqrt_in[SQRT_IN_WIDTH-1])
        error <= 1;
    else
        error <=0;
end

//convert b to DOUT_WIDTH
wire signed [DOUT_WIDTH-1:0] b_resize;

signed_cast #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT)
) sqrt_out_cast (
    .clk(clk), 
    .din(b_r[2*DIN_WIDTH+:DIN_WIDTH]),
    .din_valid(1'b1),
    .dout(b_resize),
    .dout_valid()
);

//delay b_resize
reg [3*DOUT_WIDTH-1:0] b_shift=0;
always@(posedge clk)begin
    b_shift <= {b_shift[2*DOUT_WIDTH-1:0], b_resize};
end

//delay the error flag
reg error_r =0;
always@(posedge clk)
    error_r <= error;

assign dout_error = error_r;

reg signed [DOUT_WIDTH-1:0] b_minus=0;
reg signed [DOUT_WIDTH-1:0] x1_r=0, x2_r=0;
reg dout_valid_r=0;

wire signed [DOUT_WIDTH-1:0] b_shifted = $signed(b_shift[DOUT_WIDTH+:DOUT_WIDTH]);  //check

always@(posedge clk)begin
    //b_minus <= ~b_shift[2*DOUT_WIDTH-:DOUT_WIDTH]+1'b1;
    b_minus <= ~b_shifted+1'b1;
    if(sqrt_dout_valid)begin
        x1_r <= $signed(b_minus)+$signed(sqrt_dout);
        x2_r <= $signed(b_minus)-$signed(sqrt_dout);
        dout_valid_r <= 1; 
    end
    else
        dout_valid_r <=0;
end

assign x1 = x1_r>>>1;
assign x2 = x2_r>>>1;

assign dout_valid = dout_valid_r;

endmodule
