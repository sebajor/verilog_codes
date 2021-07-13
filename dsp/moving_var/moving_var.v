`default_nettype none
`include "includes.v"

module moving_var #(
    parameter DIN_WIDTH = 25,
    parameter DIN_POINT = 24,
    parameter WINDOW_LEN = 16,
    parameter APROX = "nearest"
) (
    input wire clk,
    input wire rst,
    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,

    output wire signed [DIN_WIDTH-1:0] moving_avg,
    output wire signed [2*DIN_WIDTH:0] moving_var,
    output wire dout_valid
);
//input register to improve timming
reg [DIN_WIDTH-1:0] din_reg=0;
reg din_valid_r = 0;

always@(posedge clk)begin
    din_reg <= din;
    din_valid_r <= din_valid;
end

localparam POW_POINT = 2*DIN_POINT;
wire signed [2*DIN_WIDTH-1:0] pow_din;
wire pow_din_valid;

//it has 4 delay cycles
dsp48_mult #(
    .DIN1_WIDTH(DIN_WIDTH),
    .DIN2_WIDTH(DIN_WIDTH), 
    .DOUT_WIDTH(2*DIN_WIDTH) 
) square_input_data (
    .clk(clk),
    .din1(din_reg),
    .din2(din_reg),
    .din_valid(din_valid_r),
    .dout(pow_din),
    .dout_valid(pow_din_valid)
);


//moving average of the power
wire [2*DIN_WIDTH-1:0] pow_ma;
wire pow_ma_valid;

moving_average #(
    .DIN_WIDTH(2*DIN_WIDTH),
    .DIN_POINT(2*DIN_POINT),
    .WINDOW_LEN(WINDOW_LEN),
    .DOUT_WIDTH(2*DIN_WIDTH),
    .APPROX(APROX)
) pow_mov_avg (
    .clk(clk),
    .rst(rst),
    .din(pow_din),
    .din_valid(pow_din_valid),
    .dout(pow_ma),
    .dout_valid(pow_ma_valid)
);


//input moving average
wire signed [DIN_WIDTH-1:0] din_mov_avg;
wire din_mov_avg_valid;

moving_average #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .WINDOW_LEN(WINDOW_LEN),
    .DOUT_WIDTH(DIN_WIDTH),
    .APPROX(APROX)
) input_mov_avg (
    .clk(clk),
    .rst(rst),
    .din(din_reg),
    .din_valid(din_valid_r),
    .dout(din_mov_avg),
    .dout_valid(din_mov_avg_valid)
);

//pow of the average
wire signed [2*DIN_WIDTH-1:0] ma_pow;
wire ma_pow_valid; 

dsp48_mult #(
    .DIN1_WIDTH(DIN_WIDTH),
    .DIN2_WIDTH(DIN_WIDTH), 
    .DOUT_WIDTH(2*DIN_WIDTH) 
) square_average_data (
    .clk(clk),
    .din1(din_mov_avg),
    .din2(din_mov_avg),
    .din_valid(din_mov_avg_valid),
    .dout(ma_pow),
    .dout_valid(ma_pow_valid)
);

//obtain variance from E(x)^2-E(x^2)
reg signed [2*DIN_WIDTH:0] var_reg = 0;
reg var_reg_valid=0;
always@(posedge clk)begin
    var_reg_valid <= ma_pow_valid;
    var_reg <= $signed(pow_ma)-$signed(ma_pow);
end

//align the average with the variance (just 4 delays)
reg [6*DIN_WIDTH-1:0] avg_reg=0;
reg debug=0;
always@(posedge clk)begin
    avg_reg <= {avg_reg[5*DIN_WIDTH-1:0], din_mov_avg};
    debug <= var_reg_valid;
end


assign moving_avg = avg_reg[5*DIN_WIDTH-1:4*DIN_WIDTH];
assign moving_var = var_reg;
assign dout_valid = var_reg_valid;


endmodule
