`default_nettype none

/*
*   Author: Sebastian Jorquera
*
*   solve a quadratic eigen value problem..
*   In uesprit with 2 antennas we have:
*    
*   lamb**2-(r11+r22)*lamb+(r11*r22)-r12**2=0
*   ax**2+bx+c=0 -->
*   a = 1, b=-(r11+r22) c=(r11*r22)-r12**2
*
*   The eigen vector is -(r11-lamb)/r12 
*
*   This implementation use an iterative algorithm to calculate the sqrt
*
*/

module quad_eigen_iterative #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 15,
    parameter SQRT_WIDTH = 16,
    parameter SQRT_POINT = 8,
    parameter DOUT_WIDTH = 16,
    parameter DOUT_POINT = 13,
    parameter BANDS = 4,
    parameter FIFO_DEPTH = 8    //2**
) (
    input wire clk,

    input wire [DIN_WIDTH-1:0] r11, r22,
    input wire signed [DIN_WIDTH-1:0] r12,
    input wire din_valid,
    input wire [$clog2(BANDS)-1:0] band_in,

    output wire signed [DOUT_WIDTH-1:0] lamb1, lamb2,
    output wire signed [DOUT_WIDTH-1:0] eigen1_y, eigen2_y, eigen_x,
    //the correct eigen value is eigen_y/eigen_x, but the output of this
    //module goes into a arctan so we are happy with that :)
    output wire dout_valid,
    output wire dout_error,
    output wire [$clog2(BANDS)-1:0] band_out,
    output wire fifo_full
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

//delay the bands
reg [$clog2(BANDS)-1:0] band_r=0;
always@(posedge clk)
    band_r <= band_in;


//we want to delay the data to match the input of the quad_root_iterative
//then we store it in a fifo to match the output
wire signed [DOUT_WIDTH-1:0] r11_delay, r12_delay;
wire [$clog2(BANDS)-1:0] band_delay;
delay #(
    .DATA_WIDTH(2*DOUT_WIDTH+$clog2(BANDS)),
    .DELAY_VALUE(5)
) delay_r11_r22 (
    .clk(clk),
    .din({r11_cast, r12_cast, band_r}),
    .dout({r11_delay, r12_delay, band_delay})
);



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


//root calculation
wire signed [SQRT_WIDTH-1:0] eigval1, eigval2;
wire eigval_valid, eigval_error;

quad_root_iterative #(
    .DIN_WIDTH(DIN_WIDTH+1),
    .DIN_POINT(DIN_POINT),
    .SQRT_WIDTH(SQRT_WIDTH),
    .SQRT_POINT(SQRT_POINT),
    .FIFO_DEPTH(FIFO_DEPTH),
    .BANDS(BANDS)
) quad_root_inst  (
    .clk(clk),
    .b(b_rr),
    .c(c),
    .din_valid(c_valid),
    .fifo_full(fifo_full),
    .band_in(),
    .x1(eigval1),
    .x2(eigval2),
    .dout_valid(eigval_valid),
    .dout_error(eigval_error),
    .band_out()
);

//fifo to store r11_delay and r12_delay
wire fifo_write_ready;
wire fifo_valid;
wire signed [DOUT_WIDTH-1:0] r11_data, r12_data;
wire [$clog2(BANDS)-1:0] band_data;
axis_fifo #
(
    .DEPTH(2**FIFO_DEPTH),
    .DATA_WIDTH(2*DOUT_WIDTH+$clog2(BANDS))
) axis_fifo_inst
(
    .clk(clk),
    .rst(1'b0),
    .s_axis_tdata({r11_delay, r12_delay, band_delay}),
    .s_axis_tkeep(),
    .s_axis_tvalid(c_valid),
    .s_axis_tready(fifo_write_ready),
    .s_axis_tlast(),
    .s_axis_tid(),
    .s_axis_tdest(),
    .s_axis_tuser(),
    .m_axis_tdata({r11_data, r12_data, band_data}),
    .m_axis_tkeep(),
    .m_axis_tvalid(fifo_valid),
    .m_axis_tready(eigval_valid),
    .m_axis_tlast(),
    .m_axis_tid(),
    .m_axis_tdest(),
    .m_axis_tuser(),
    .status_overflow(),
    .status_bad_frame(),
    .status_good_frame(),
    .fifo_full()
);


reg signed [DOUT_WIDTH-1:0] eigvec1=0, eigvec2=0, eigfrac=0;
reg signed [DOUT_WIDTH-1:0] eigval1_r=0, eigval2_r=0;
reg eigen_valid=0;
reg eigen_error=0;

//TODO check if the sign is implicit increased
wire signed [DOUT_WIDTH-1:0] eig1_sized, eig2_sized;
generate 
    if(DOUT_POINT>SQRT_POINT)begin
        assign eig1_sized = (eigval1<<<(DOUT_POINT-SQRT_POINT));
        assign eig2_sized = (eigval2<<<(DOUT_POINT-SQRT_POINT));
    end
    else if(DOUT_POINT<SQRT_OUT_POINT)begin
        assign eig1_sized = (eigval1>>>(SQRT_POINT-DOUT_POINT));
        assign eig2_sized = (eigval2>>>(SQRT_POINT-DOUT_POINT));
    end
    else begin
        assign eig1_sized = eigval1;
        assign eig2_sized = eigval2;

    end
endgenerate
reg [$clog2(BANDS)-1:0] band_dout=0;
always@(posedge clk)begin
    band_dout <= band_data;
    eigval1_r <= $signed(eig1_sized);   eigval2_r <= $signed(eig2_sized);
    eigen_valid <= $signed(eigval_valid);
    eigvec1 <= $signed(r11_data)-$signed(eig1_sized);
    eigvec2 <= $signed(r11_data)-$signed(eig2_sized);
    eigfrac <= $signed(r12_data);
    eigen_error <= eigval_error;
end

assign lamb1 = eigval1_r;
assign lamb2 = eigval2_r;
assign dout_valid = eigen_valid;
assign eigen1_y = ~eigvec1+1'b1;
assign eigen2_y = ~eigvec2+1'b1;
assign eigen_x = eigfrac;
assign dout_error = eigen_error;
assign band_out = band_dout;

endmodule
