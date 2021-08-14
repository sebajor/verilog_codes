`default_nettype none

/*
    typical solution of the quadratic equation
    x1 = (-b +sqrt(b**2-4ac))/2a
    x2 = (-b- sqrt(b**2-4ac))/2a
    
    for 2 antenna doa we have a =1 so we just have as input b,c 
    also we normalize the input ie c,b have ine int bit
    
    Look out the sqrt_in_width and sqrt_out_width.. the square root
    is calculated using a rom, so the size matter!
*/

module quad_root #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    parameter SQRT_IN_WIDTH = 10,
    parameter SQRT_IN_PT = 7,       //the biggest value at the input square should be 4
    parameter SQRT_OUT_WIDTH = 16,
    parameter SQRT_OUT_PT = 13,
    parameter SQRT_MEM_FILE = "sqrt.hex"
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] b, c,
    input wire din_valid,

    output wire signed [SQRT_OUT_WIDTH-1:0] x1,x2,
    output wire dout_valid,
    output wire dout_error
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

//difference between b**2-4ac
wire signed [2*DIN_WIDTH-1:0] b2_shift = b2>>>(2);   //align the points

reg diff_valid=0;
reg signed [2*DIN_WIDTH-1:0] diff=0;
always@(posedge clk)begin
    diff_valid <= b2_valid;
    if(b2_valid)
        diff <= $signed(b2_shift)-$signed(c4);
end

//convert the data into sqrt input 
localparam DIFF_POINT = 2*DIN_POINT-2;
wire [SQRT_IN_WIDTH-1:0] sqrt_in;
wire sqrt_in_valid;
signed_cast #(
    .DIN_WIDTH(2*DIN_WIDTH),
    .DIN_POINT(DIFF_POINT),
    .DOUT_WIDTH(SQRT_IN_WIDTH),
    .DOUT_POINT(SQRT_IN_PT)
)sqrt_in_cast (
    .clk(clk), 
    .din(diff),
    .din_valid(diff_valid),
    .dout(sqrt_in),
    .dout_valid(sqrt_in_valid)
);



wire [SQRT_OUT_WIDTH-1:0] sqrt_dout;

sqrt_lut #(
    .DIN_WIDTH(SQRT_IN_WIDTH),
    .DIN_POINT(SQRT_IN_PT),
    .DOUT_WIDTH(SQRT_OUT_WIDTH),
    .DOUT_POINT(SQRT_OUT_PT),
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


//check if the input of the sqrt is postive
reg error=0;
always@(posedge clk)begin
    if(sqrt_in[SQRT_IN_WIDTH-1])
        error <= 1;
    else
        error <=0;
end

//convert b to SQRT_OUT_WIDTH
wire signed [SQRT_OUT_WIDTH-1:0] b_resize;

signed_cast #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .DOUT_WIDTH(SQRT_OUT_WIDTH),
    .DOUT_POINT(SQRT_OUT_PT)
)sqrt_out_cast (
    .clk(clk), 
    .din(b_rrr),
    .din_valid(1'b1),
    .dout(b_resize),
    .dout_valid()
);

//delay b_resize
reg [3*SQRT_OUT_WIDTH-1:0] b_shift =0;
always@(posedge clk)begin
    b_shift <= {b_shift[2*SQRT_OUT_WIDTH-1:0], b_resize};
end


//delay error
//check!
reg error_r =0;
always@(posedge clk)
    error_r <= error;

assign dout_error = error_r;


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
