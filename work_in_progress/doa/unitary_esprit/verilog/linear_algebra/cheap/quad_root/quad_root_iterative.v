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
*   For the square root we use an iterative algorithm
*   so the input interface is a fifo
*/

module quad_root_iterative #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    parameter SQRT_WIDTH = 10,
    parameter SQRT_POINT = 7,
    parameter FIFO_DEPTH = 8,    //Address= 2**FIFO_DEPTH
    parameter BANDS = 4
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] b,c,
    input wire din_valid,
    output wire fifo_full,
    input wire [$clog2(BANDS)-1:0] band_in,

    output wire signed [SQRT_WIDTH-1:0] x1,x2,
    output wire dout_valid,
    output wire dout_error,
    output wire [$clog2(BANDS)-1:0] band_out
);

wire signed [2*DIN_WIDTH-1:0] b2;
wire b2_valid;

//4 delay
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
wire signed [DIN_WIDTH-1:0] c_r, b_r;
wire [$clog2(BANDS)-1:0] bands_r;
delay #(
    .DATA_WIDTH(2*DIN_WIDTH+$clog2(BANDS)),
    .DELAY_VALUE(3)
) delay_b_c (
    .clk(clk),
    .din({b,c, band_in}),
    .dout({b_r,c_r, bands_r})
);


//4*c
reg signed [2*DIN_WIDTH-1:0] c4=0;
always@(posedge clk)begin
    c4 <= $signed(c_r)<<<(DIN_POINT);    //we set the point in 2*DIN_PT-2
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

//convert the b to the SQRT_WIDTH
wire signed [SQRT_WIDTH-1:0] b_resize;

signed_cast #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .DOUT_WIDTH(SQRT_WIDTH),
    .DOUT_POINT(SQRT_POINT)
) sqrt_out_cast (
    .clk(clk), 
    .din(b_r),
    .din_valid(1'b1),
    .dout(b_resize),
    .dout_valid()
);

//convert the data to sqrt input
localparam DIFF_POINT = 2*DIN_POINT-2;
wire [SQRT_WIDTH-1:0] sqrt_in;
wire sqrt_in_valid;


signed_cast #(
    .DIN_WIDTH(2*DIN_WIDTH),
    .DIN_POINT(DIFF_POINT),
    .DOUT_WIDTH(SQRT_WIDTH),
    .DOUT_POINT(SQRT_POINT)
) sqrt_in_cast (
    .clk(clk), 
    .din(diff),
    .din_valid(diff_valid),
    .dout(sqrt_in),
    .dout_valid(sqrt_in_valid)
);

wire [SQRT_WIDTH-1:0] sqrt_data;
wire sqrt_valid, read_req;

//delay b_resize to match the diff
wire signed [SQRT_WIDTH-1:0] b_delay;
wire [$clog2(BANDS)-1:0] bands_rr;

delay #(
    .DATA_WIDTH(SQRT_WIDTH),
    .DELAY_VALUE(2)
) delay_b_resize (
    .clk(clk),
    .din(b_resize),
    .dout(b_delay)
);

delay #(
    .DATA_WIDTH($clog2(BANDS)),
    .DELAY_VALUE(3)
) delay_bands (
    .clk(clk),
    .din(bands_r),
    .dout(bands_rr)
);


wire signed [SQRT_WIDTH-1:0] b_data;
wire [$clog2(BANDS)-1:0] bands_rrr;

fifo_sync #(
    .DIN_WIDTH(2*SQRT_WIDTH+$clog2(BANDS)),
    .FIFO_DEPTH(FIFO_DEPTH)
) fifo_sync_inst (
    .clk(clk),
    .rst(1'b0),
    .wdata({sqrt_in, b_delay, bands_rr}),
    .w_valid(sqrt_in_valid),
    .full(fifo_full),
    .empty(),
    .rdata({sqrt_data, b_data, bands_rrr}),
    .r_valid(sqrt_valid),
    .read_req(~read_req)
);

wire [SQRT_WIDTH-1:0] sqrt_dout;
wire sqrt_out_valid;

iterative_sqrt #(
    .DIN_WIDTH(SQRT_WIDTH),
    .DIN_POINT(SQRT_POINT)
) iterative_sqrt_inst (
    .clk(clk),
    .busy(read_req),
    .din_valid(sqrt_valid & !sqrt_data[SQRT_WIDTH-1]),
    .din(sqrt_data),
    .dout(sqrt_dout),
    .reminder(),
    .dout_valid(sqrt_out_valid)
);


wire signed [SQRT_WIDTH-1:0] b_delay_r;
wire [$clog2(BANDS)-1:0] bands_delay;
delay #(
    .DATA_WIDTH(SQRT_WIDTH+$clog2(BANDS)),
    .DELAY_VALUE((SQRT_WIDTH+SQRT_POINT)/2)
) delay_b_again (
    .clk(clk),
    .din({b_data, bands_rrr}),
    .dout({b_delay_r, bands_delay})
);

reg error=0;
always@(posedge clk)begin
    if(sqrt_data[SQRT_WIDTH-1] & sqrt_valid)
        error <= 1;
    else
        error <=0;
end

wire error_delay;
delay #(
    .DATA_WIDTH(1),
    .DELAY_VALUE((SQRT_WIDTH+SQRT_POINT)/2-1)
) delay_error (
    .clk(clk),
    .din(error),
    .dout(error_delay)
);

reg signed [SQRT_WIDTH-1:0] b_minus=0;
reg signed [SQRT_WIDTH-1:0] x1_r=0, x2_r=0;
reg dout_valid_r=0;

always@(posedge clk)begin
    b_minus <= ~b_delay_r+1'b1;
    if(sqrt_out_valid)begin
        x1_r <= $signed(b_minus)+$signed(sqrt_dout);
        x2_r <= $signed(b_minus)-$signed(sqrt_dout);
        dout_valid_r <=1;
    end
    else
        dout_valid_r <=0;
end

assign x1 = x1_r>>>1;
assign x2 = x2_r>>>1;

assign dout_valid = dout_valid_r;

endmodule
