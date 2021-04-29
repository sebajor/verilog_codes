`default_nettype none 
`include "includes.v"

module eigen #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 15,
    parameter SQRT_IN_WIDTH = 10,
    parameter SQRT_IN_POINT = 7,
    parameter DOUT_WIDTH = 16,
    parameter DOUT_POINT = 13
) (
    input wire clk,

    input wire [DIN_WIDTH-1:0] r11, r22,
    input wire signed [DIN_WIDTH-1:0] r12,
    input wire din_valid,

    output wire signed [DOUT_WIDTH-1:0] lamb1, lamb2,
    output wire signed [DOUT_WIDTH-1:0] eigen1_x, eigen2_x, eigen_y,
    //the correct eigen value is eigen_x/eigen_y, but the output of this
    //module goes into a arctan so we are happy with that :)
    output wire dout_valid
);

//for uesprit we have to solve a quadratic eigenvalue problem
// lamb**2 -(r11+r22)lamb+(r11*r22)-r12**2 = 0
// ax**2+bx+c = 0 ---> a=1, b=-(r11+r22), c=(r11*r22)-r12**2


//the eigenvector is given by -(r11-lamb)/r12, so we need to shift those 
//for the whole process of calculate the eigenvalues
reg [(13*DIN_WIDTH)-1:0] r11_shift =0, r12_shift=0;
always@(posedge clk)begin
    r11_shift <= {r11_shift[12*DIN_WIDTH-1:0], r11};
    r12_shift <= {r12_shift[12*DIN_WIDTH-1:0], r12};
end

wire [DIN_WIDTH-1:0] r11_delay, r12_delay;
assign r11_delay = r11_shift[13*DIN_WIDTH-1-:DIN_WIDTH];
assign r12_delay = r12_shift[13*DIN_WIDTH-1-:DIN_WIDTH];


//get the coeficients
wire [2*DIN_WIDTH-1:0] r11_r22=0, r12_2 =0;
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
    .din2(r22),
    .din_valid(din_valid),
    .dout(r12_2),
    .dout_valid()
);

localparam MULTS_WIDTH = 2*DIN_WIDTH;
localparam MULTS_PT = 2*DIN_POINT;
localparam MULTS_INT = MULTS_WIDTH-MULTS_PT;

reg [DIN_WIDTH-1:0] r11_r22_resize=0, r12_2_resize=0;
reg signed [DIN_WIDTH:0] c=0;
reg r12_2_valid=0, c_valid=0;
always@(posedge clk)begin
    r11_r22_resize <= r11_r22[MULTS_WIDTH-1-:DIN_WIDTH];    //mutls_widht-2? o -1??
    r12_2_resize <= r12_2[MULTS_WIDTH-1-:DIN_WIDTH];
    r12_2_valid <= mult_valid;
    c_valid <= r12_2_valid;
    c <= $signed(r11_r22_resize)-$signed(r12_2_resize);
end


//check timming !
reg [DIN_WIDTH:0] b=0, b_r=0,b_rr=0, b_rrr=0;
always@(posedge clk)begin
    b <= $signed(r11)+$signed(r22);
    b_r <= ~b+1'b1;    //negate
    b_rr <= b_r;    b_rrr <= b_rr;
end

//eigenvalues, 8 delays
wire signed [DOUT_WIDTH-1:0] eigval1, eigval2;
wire eigval_valid;

quad_root #(
    .DIN_WIDTH(DIN_WIDTH+1),
    .SQRT_IN_WIDTH(SQRT_IN_WIDTH), 
    .SQRT_IN_PT(SQRT_IN_POINT),
    .SQRT_OUT_WIDTH(DOUT_WIDTH), 
    .SQRT_OUT_PT(DOUT_POINT) 
) quad_root_inst(
    .clk(clk),
    .b(b_rrr),
    .c(c),
    .din_valid(c_valid),
    .x1(eigval1),
    .x2(eigval2),
    .dout_valid(eigval_valid)
);

reg signed [DOUT_WIDTH-1:0] eigvec1=0, eigvec2=0, eigfrac=0;
reg signed [DOUT_WIDTH-1:0] eigval1_r=0, eigval2_r=0;
reg eigen_valid =0;
always@(posedge clk)begin
    eigval1_r <= eigval1;   eigval2_r <= eigval2;
    eigen_valid <= eigval_valid;
    eigvec1 <= $signed(r11_delay)-$signed(eigval1);
    eigvec2 <= $signed(r11_delay)-$signed(eigval2);
    eigfrac <= $signed(r12_delay);
end

assign lamb1 = eigval1_r;
assign lamb2 = eigval2_r;
assign dout_valid = eigen_valid;
assign eigen1_x = ~eigvec1+1'b1;
assign eigen2_x = ~eigvec2+1'b1;
assign eigen_y = eigfrac;

endmodule
