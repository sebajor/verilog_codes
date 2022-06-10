`default_nettype none

module sobel #(
    parameter DIN_WIDTH = 8,
    parameter DIN_POINT = 7,
    parameter KERNEL_SIZE = 3,
    parameter WEIGHT_WIDTH = 8,
    parameter WEIGHT_POINT = 7,
    parameter X_SOBEL_FILE = "weight/x_sobel.mem",
    parameter Y_SOBEL_FILE = "weight/x_sobel.mem",
    parameter DOUT_WIDTH = 8,
    parameter DOUT_POINT = 7
) (
    input wire clk,
    input wire [KERNEL_SIZE*KERNEL_SIZE*DIN_WIDTH-1:0] din,
    input wire din_valid,
    output wire [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);

wire [DOUT_WIDTH-1:0] x_sobel, y_sobel;
wire sobel_valid;

image_convolution #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .KERNEL_SIZE(KERNEL_SIZE),
    .WEIGHT_WIDTH(WEIGHT_WIDTH),
    .WEIGHT_POINT(WEIGHT_POINT),
    .WEIGHT_FILE(X_SOBEL_FILE),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT)
) x_sobel_inst (
    .clk(clk),
    .din(din),
    .din_valid(din_valid),
    .dout(x_sobel),
    .dout_valid(sobel_valid)
);


image_convolution #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .KERNEL_SIZE(KERNEL_SIZE),
    .WEIGHT_WIDTH(WEIGHT_WIDTH),
    .WEIGHT_POINT(WEIGHT_POINT),
    .WEIGHT_FILE(Y_SOBEL_FILE),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT)
) y_sobel_inst (
    .clk(clk),
    .din(din),
    .din_valid(din_valid),
    .dout(y_sobel),
    .dout_valid()
);


reg signed [DOUT_WIDTH:0] dout_r=0;
reg dout_valid_r=0;
always@(posedge clk)begin
    dout_r <= $signed(x_sobel)+$signed(y_sobel);
    dout_valid_r <= sobel_valid;
end

assign dout = dout_r>>>1;
assign dout_valid = dout_valid_r;

endmodule
