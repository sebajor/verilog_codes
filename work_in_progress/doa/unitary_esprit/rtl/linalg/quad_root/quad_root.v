`default_nettype none
`include "dsp48_mult.v"
`include "sqrt_lut.v"
`include "signed_cast.v"
/* Typical solution of the quadratic equation
x1 = (-b +sqrt(b**2-4ac))/2a
x2 = (-b- sqrt(b**2-4ac))/2a

To keep it simple we take a=1

So the input are B,C
*/

module quad_root #(
    parameter DIN_WIDTH = 8,
    parameter DIN_POINT = 7,
    parameter DOUT_WIDTH = 8,
    parameter DOUT_POINT = 7,
    parameter SQUARE_ALGO = "lut"   //type of implementation of the algorithm
) (
    input wire clk,
    
    input wire din_valid,
    input wire [DIN_WIDTH-1:0] b,
    input wire [DIN_WIDTH-1:0] c,

    output wire [DOUT_WIDTH-1:0] x1,
    output wire [DOUT_WIDTH-1:0] x2,
    output wire dout_valid
);

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

localparam SQUARE_POINT = 2*DIN_POINT;

//sync everything
reg signed [DIN_WIDTH-1:0] c_r=0, c_rr=0, c_rrr=0;
reg signed [DIN_WIDTH-1:0] b_r=0, b_rr=0, b_rrr=0;
always@(posedge clk)begin
    c_r <= c;   c_rr<=c_r;  c_rrr<=c_rr;
    b_r <= b;   b_rr<=b_r;  b_rrr<=b_rr;
end

reg signed [2*DIN_WIDTH-1:0] c4=0;
always@(posedge clk)begin
    //if we have normalized b and c, ie we use just one int bit then 
    //if c>0.25 there is no chance that the solution were real..
    //also the shift could make an overflow! Review!!!!
    c4 <= c_rrr<<<(DIN_POINT+2);    //align points with b2 and shift it two to multiply by 4
end

//b**2-4ac
reg diff_valid =0;
reg signed [2*DIN_WIDTH-1:0] diff=0;
always@(posedge clk)begin
    diff_valid <= b2_valid;
    if(b2_valid)begin
        diff <= $signed(b2)-$signed(c4);
    end
end

wire det = diff_valid & ~diff[2*DIN_WIDTH-1];   //its valid when the determinant is non neg

wire signed [DOUT_WIDTH-1:0] sqrt_dout;
wire sqrt_dout_valid;
//square root
generate 
//to have different options...
    if(SQUARE_ALGO=="lut")begin
    //you have to run the sqrt_gen before with the right parameters!
    sqrt_lut #(
        .DIN_WIDTH(2*DIN_WIDTH),
        .DIN_POINT(2*DIN_POINT),
        .DOUT_WIDTH(DOUT_WIDTH),
        .DOUT_POINT(DOUT_POINT),
        .SQRT_FILE("sqrt.hex")
    ) sqrt_inst (
        .clk(clk),
        .din(diff),
        .din_valid(det),
        .dout(sqrt_dout),
        .dout_valid(sqrt_dout_valid)
    );
    end
    else begin
    sqrt_lut #(
        .DIN_WIDTH(2*DIN_WIDTH),
        .DIN_POINT(2*DIN_POINT),
        .DOUT_WIDTH(DOUT_WIDTH),
        .DOUT_POINT(DOUT_POINT),
        .SQRT_FILE("sqrt.hex")
    ) sqrt_inst (
        .clk(clk),
        .din(diff),
        .din_valid(det),
        .dout(sqrt_dout),
        .dout_valid(sqrt_dout_valid)
    );
    end
endgenerate 

//delay to match the sqrt output
reg [2*DIN_WIDTH-1:0] b_shift =0;
always@(posedge clk)begin        
    b_shift <= {b_shift[DIN_WIDTH-1:0],b_rrr};  
end

//align bitpoint of the sqrt
localparam DIN_INT = DIN_WIDTH-DIN_POINT;
localparam DOUT_INT = DOUT_WIDTH-DOUT_POINT;



wire signed [DOUT_WIDTH-1:0] b_align;
generate
if((DOUT_WIDTH==DIN_WIDTH))begin
    if(DOUT_POINT==DIN_POINT)
        assign b_align = b_shift[DIN_WIDTH+:DIN_WIDTH];
    else if(DOUT_POINT>DIN_POINT)begin
        //assign b_align = b_shift[DIN_WIDTH+:DIN_WIDTH] >>>(DOUT_POINT-DIN_POINT);
        assign b_align = $signed(b_shift[DIN_WIDTH+:DIN_WIDTH]) <<<(DOUT_POINT-DIN_POINT);
    end
    else begin
        //assign b_align = b_shift[DIN_WIDTH+:DIN_WIDTH] <<<(DIN_POINT-DOUT_POINT);
        assign b_align = $signed(b_shift[DIN_WIDTH+:DIN_WIDTH]) >>>(DIN_POINT-DOUT_POINT);
    end
end
else begin
    signed_cast #(
        .PARALLEL(1),
        .DIN_WIDTH(DIN_WIDTH),
        .DIN_INT(DIN_INT),
        .DOUT_WIDTH(DOUT_WIDTH),
        .DOUT_INT(DOUT_INT)
    ) b_cast (
        .clk(clk),
        .din(b_shift[DIN_WIDTH+:DIN_WIDTH]),
        .din_valid(1'b1),
        .dout(b_align),
        .dout_valid()
    );
end
endgenerate





//calculate b+-...
reg signed [DOUT_WIDTH-1:0] b_minus=0;
reg signed [DOUT_WIDTH-1:0] x1_r=0, x2_r=0;
reg dout_valid_r=0;
always@(posedge clk)begin
    b_minus <= ~b_align+1'b1;   //inverting in 2 complement
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
