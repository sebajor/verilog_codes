//`default_nettype none
`include "dsp48_mult.v"
`include "moving_average.v"

module moving_var #(
    parameter DIN_WIDTH = 25,
    parameter DIN_POINT = 24,
    parameter WINDOW_LEN = 16,
    parameter APPROX = "nearest"
)(
    input wire clk,
    input wire rst,
    input wire signed [DIN_WIDTH-1:0] din,
    input wire din_valid,
    
    output wire signed [DIN_WIDTH-1:0] moving_avg,
    output wire signed [2*DIN_WIDTH-1:0] moving_var,
    output wire dout_valid
);

//register the input to improve timming
reg [DIN_WIDTH-1:0] din_reg=0;
reg din_valid_reg=0;
always@(posedge clk)begin
	din_reg <= din;
	din_valid_reg <= din_valid;
end


localparam SQUARE_POINT = 2*DIN_POINT;
wire signed [2*DIN_WIDTH-1:0] square_din;
wire square_din_valid;

dsp48_mult #(
    .DIN1_WIDTH(DIN_WIDTH),
    .DIN2_WIDTH(DIN_WIDTH),
    .DOUT_WIDTH(2*DIN_WIDTH)
) square_input_data (
    .clk(clk),
    .din1(din_reg),
    .din2(din_reg),
    .din_valid(din_valid_reg),
    .dout(square_din),
    .dout_valid(square_din_valid)
);

//mult has 3 delays, check
reg [4*DIN_WIDTH-1:0] din_dly=0;
reg [3:0] din_valid_dly=0, rst_dly;
always@(posedge clk)begin
    din_valid_dly <= {din_valid_dly[2:0], din_valid_reg};
    din_dly <= {din_dly[3*DIN_WIDTH-1:0], din_reg};
    rst_dly <= {rst_dly[3:0], rst};
end

//moving windows 
wire signed [DIN_WIDTH-1:0] din_ma;
wire din_ma_valid;
moving_average #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .WINDOW_LEN(WINDOW_LEN),
    .DOUT_WIDTH(DIN_WIDTH),
    .APPROX(APPROX)
) din_mov_avg (
    .clk(clk),
    .rst(rst_dly),
    .din(din_dly[4*DIN_WIDTH-1-:DIN_WIDTH]),
    .din_valid(din_valid_dly[3]),
    .dout(din_ma),
    .dout_valid(din_ma_valid)
);

wire signed [2*DIN_WIDTH-1:0] square_ma;
wire square_ma_valid;
moving_average #(
    .DIN_WIDTH(2*DIN_WIDTH),
    .DIN_POINT(2*DIN_POINT),
    .WINDOW_LEN(WINDOW_LEN),
    .DOUT_WIDTH(2*DIN_WIDTH),
    .APPROX(APPROX)
) square_mov_avg (
    .clk(clk),
    .rst(rst_dly),
    .din(square_din),
    .din_valid(square_din_valid),
    .dout(square_ma),
    .dout_valid(square_ma_valid)
);


//square of the din_ma
wire signed [2*DIN_WIDTH-1:0] square_din_ma;
wire square_din_ma_valid;

dsp48_mult #(
    .DIN1_WIDTH(DIN_WIDTH),
    .DIN2_WIDTH(DIN_WIDTH),
    .DOUT_WIDTH(2*DIN_WIDTH)
) square_input (
    .clk(clk),
    .din1(din_ma),
    .din2(din_ma),
    .din_valid(din_ma_valid),
    .dout(square_din_ma),
    .dout_valid(square_din_ma_valid)
);

//4 delay for the square_ma
reg signed [4*(2*DIN_WIDTH)-1:0] ma2_dly=0;
reg [3:0] ma2_valid_dly=0;
always@(posedge clk)begin
    ma2_dly <= {ma2_dly[3*(2*DIN_WIDTH)-1:0], square_ma};
    ma2_valid_dly <= {ma2_valid_dly[2:0], square_ma_valid};
end

//substract both branches
reg signed [2*DIN_WIDTH-1:0] ma_sub=0;
reg dout_valid_r=0;

always@(posedge clk)begin
    ma_sub <= $signed(ma2_dly[4*2*DIN_WIDTH-1-:2*DIN_WIDTH])-$signed(square_din_ma);
    //dout_valid_r <= square_ma_valid;
    dout_valid_r <= square_din_ma_valid;
end

//put 4 delays in the moving average to sync with the variance
reg signed [5*DIN_WIDTH-1:0] ma_dout=0;
always@(posedge clk)begin
    ma_dout <= {ma_dout[4*DIN_WIDTH-1:0], din_ma};
end

assign moving_var = ma_sub;
assign moving_avg = ma_dout[5*DIN_WIDTH-1-:DIN_WIDTH];
assign dout_valid = dout_valid_r;


endmodule
