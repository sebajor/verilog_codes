`default_nettype none

/*
solve a quadratic eigen value problem..
In uesprit with 2 antennas we have:
    lamb**2-(r11+r22)*lamb+(r11*r22)-r12**2=0
    ax**2+bx+c=0 -->
    a = 1, b=-(r11+r22) c=(r11*r22)-r12**2

The eigen vector is -(r11-lamb)/r12 
*/

module quad_eigen #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 15,
    parameter SQRT_IN_WIDTH = 10,
    parameter SQRT_IN_POINT = 7,
    parameter SQRT_OUT_WIDTH = 16,
    parameter SQRT_OUT_POINT = 13,
    parameter SQRT_MEM_FILE = "rtl/sqrt.hex",
    parameter DOUT_WIDTH = 16,
    parameter DOUT_POINT = 13
) (
input wire clk,

    input wire [DIN_WIDTH-1:0] r11, r22,
    input wire signed [DIN_WIDTH-1:0] r12,
    input wire din_valid,

    output wire signed [DOUT_WIDTH-1:0] lamb1, lamb2,
    output wire signed [DOUT_WIDTH-1:0] eigen1_y, eigen2_y, eigen_x,
    //the correct eigen value is eigen_y/eigen_x, but the output of this
    //module goes into a arctan so we are happy with that :)
    output wire dout_valid,
    output wire dout_error
);

//transform r11, r12 to dout_width and keep it until the eigen val is calculated
//we need those for the eigenvector
wire [DOUT_WIDTH-1:0] r11_cast, r12_cast;

signed_cast #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT)
) cast_r11 (
    .clk(clk), 
    .din(r11),
    .din_valid(1'b1),
    .dout(r11_cast),
    .dout_valid()
);

signed_cast #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT)
) cast_r12 (
    .clk(clk), 
    .din(r12),
    .din_valid(1'b1),
    .dout(r12_cast),
    .dout_valid()
);

//delay those values to match the eigenvalue calculation
reg [(13*DOUT_WIDTH)-1:0] r11_r=0, r12_r=0;
always@(posedge clk)begin
    r11_r <= {r11_r[12*DOUT_WIDTH-1:0], r11_cast};
    r12_r <= {r12_r[12*DOUT_WIDTH-1:0], r12_cast};
end

wire [DOUT_WIDTH-1:0] r11_delay, r12_delay;
assign r11_delay = r11_r[13*DOUT_WIDTH-1-:DOUT_WIDTH];
assign r12_delay = r12_r[13*DOUT_WIDTH-1-:DOUT_WIDTH];

//now start to calculate the coeficients for the eigenvalues

//get the coeficients
wire [2*DIN_WIDTH-1:0] r11_r22, r12_2;
wire mult_valid;

//3 delays
dsp48_mult #(
    .DIN1_WIDTH(DIN_WIDTH),
    .DIN2_WIDTH(DIN_WIDTH),
    .DOUT_WIDTH(2*DIN_WIDTH)
)r11_r22_mult (
    .clk(clk),
    .rst(1'b0),
    .din1(r11),
    .din2(r22),
    .din_valid(din_valid),
    .dout(r11_r22),
    .dout_valid(mult_valid)
);

dsp48_mult #(
    .DIN1_WIDTH(DIN_WIDTH),
    .DIN2_WIDTH(DIN_WIDTH),
    .DOUT_WIDTH(2*DIN_WIDTH)
)r12_square (
    .clk(clk),
    .rst(1'b0),
    .din1(r12),
    .din2(r12),
    .din_valid(din_valid),
    .dout(r12_2),
    .dout_valid()
);


//resize the multiplications
wire signed [DIN_WIDTH-1:0] r11_r22_cast, r12_2_cast;
wire r12_2_cast_valid;

signed_cast #(
    .DIN_WIDTH(2*DIN_WIDTH),
    .DIN_POINT(2*DIN_POINT),
    .DOUT_WIDTH(DIN_WIDTH),
    .DOUT_POINT(DIN_POINT)
) cast_r12_2 (
    .clk(clk), 
    .din(r12_2),
    .din_valid(mult_valid),
    .dout(r12_2_cast),
    .dout_valid(r12_2_cast_valid)
);

signed_cast #(
    .DIN_WIDTH(2*DIN_WIDTH),
    .DIN_POINT(2*DIN_POINT),
    .DOUT_WIDTH(DIN_WIDTH),
    .DOUT_POINT(DIN_POINT)
) cast_r11_r22 (
    .clk(clk), 
    .din(r11_r22),
    .din_valid(mult_valid),
    .dout(r11_r22_cast),
    .dout_valid()
);

reg signed [DIN_WIDTH:0] c=0;
reg c_valid =0;
always@(posedge clk)begin
    c <= $signed(r11_r22_cast)-$signed(r12_2_cast);
    c_valid <= r12_2_cast_valid;
end

//check timing
reg [DIN_WIDTH:0] b=0, b_neg=0;
reg [4*(DIN_WIDTH+1)-1:0] b_r=0;
always@(posedge clk)begin
    b <= $signed(r11)+$signed(r22); 
    b_neg <= ~b+1'b1; //negate
    b_r <= {b_r[3*(DIN_WIDTH+1)-1:0], b_neg};
end

wire signed [DIN_WIDTH:0] b_rr = b_r[4*(DIN_WIDTH+1)-1:3*(DIN_WIDTH+1)];

//eigenvalues, 8 delay
wire signed [SQRT_OUT_WIDTH-1:0] eigval1, eigval2;
wire eigval_valid, eigval_error;


quad_root #(
    .DIN_WIDTH(DIN_WIDTH+1),
    .DIN_POINT(DIN_POINT),
    .SQRT_IN_WIDTH(SQRT_IN_WIDTH),
    .SQRT_IN_POINT(SQRT_IN_POINT),
    .DOUT_WIDTH(SQRT_OUT_WIDTH),
    .DOUT_POINT(SQRT_OUT_POINT),
    .SQRT_MEM_FILE(SQRT_MEM_FILE)
) quad_root_inst (
    .clk(clk),
    .b(b_rr),
    .c(c),
    .din_valid(c_valid),
    .x1(eigval1),
    .x2(eigval2),
    .dout_valid(eigval_valid),
    .dout_error(eigval_error)
);
/*
quad_root #(
    .DIN_WIDTH(DIN_WIDTH+1),
    .DIN_POINT(DIN_POINT),
    .SQRT_IN_WIDTH(SQRT_IN_WIDTH),
    .SQRT_IN_PT(SQRT_IN_POINT),
    .SQRT_OUT_WIDTH(DOUT_WIDTH),
    .SQRT_OUT_PT(DOUT_POINT),
    .SQRT_MEM_FILE(SQRT_MEM_FILE)
) quad_root_inst (
    .clk(clk),
    .b(b_rr),
    .c(c),
    .din_valid(c_valid),
    .x1(eigval1),
    .x2(eigval2),
    .dout_valid(eigval_valid),
    .dout_error(eigval_error)
);
*/
reg signed [DOUT_WIDTH-1:0] eigvec1=0, eigvec2=0, eigfrac=0;
reg signed [DOUT_WIDTH-1:0] eigval1_r=0, eigval2_r=0;
reg eigen_valid=0;
reg eigen_error=0;
//TODO check if the sign is implicit increased
wire signed [DOUT_WIDTH-1:0] eig1_sized, eig2_sized;
generate 
    if(DOUT_POINT>SQRT_OUT_POINT)begin
        assign eig1_sized = (eigval1<<<(DOUT_POINT-SQRT_OUT_POINT));
        assign eig2_sized = (eigval2<<<(DOUT_POINT-SQRT_OUT_POINT));
    end
    else if(DOUT_POINT<SQRT_OUT_POINT)begin
        assign eig1_sized = (eigval1>>>(SQRT_OUT_POINT-DOUT_POINT));
        assign eig2_sized = (eigval2>>>(SQRT_OUT_POINT-DOUT_POINT));
    end
    else begin
        assign eig1_sized = eigval1;
        assign eig2_sized = eigval2;

    end
endgenerate
always@(posedge clk)begin
    eigval1_r <= $signed(eig1_sized);   eigval2_r <= $signed(eig2_sized);
    eigen_valid <= $signed(eigval_valid);
    eigvec1 <= $signed(r11_delay)-$signed(eig1_sized);
    eigvec2 <= $signed(r11_delay)-$signed(eig2_sized);
    eigfrac <= $signed(r12_delay);
    eigen_error <= eigval_error;
end

/*
always@(posedge clk)begin
    eigval1_r <= $signed(eigval1);   eigval2_r <= $signed(eigval2);
    eigen_valid <= $signed(eigval_valid);
    eigvec1 <= $signed(r11_delay)-$signed(eigval1);
    eigvec2 <= $signed(r11_delay)-$signed(eigval2);
    eigfrac <= $signed(r12_delay);
    eigen_error <= eigval_error;
end
*/
assign lamb1 = eigval1_r;
assign lamb2 = eigval2_r;
assign dout_valid = eigen_valid;
assign eigen1_y = ~eigvec1+1'b1;
assign eigen2_y = ~eigvec2+1'b1;
assign eigen_x = eigfrac;
assign dout_error = eigen_error;


endmodule
