`default_nettype none

module systolic_tap #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    parameter COEF_WIDTH = 16,
    parameter COEF_POINT = 14,
    parameter POST_ADD = 48
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din,
    input wire signed [COEF_WIDTH-1:0] coeff,
    input wire signed [POST_ADD-1:0] post_add,
    input wire din_valid,
    
    output wire signed [POST_ADD-1:0] dout,
    output wire dout_valid,
    output wire [DIN_WIDTH-1:0] tap_delay
);

fir_tap_dsp48 #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .COEF_WIDTH(COEF_WIDTH),
    .COEF_POINT(COEF_POINT),
    .POST_ADD(POST_ADD)
) fir_tap_inst (
    .clk(clk),
    .pre_add1(din),
    .pre_add2({(DIN_WIDTH){1'b0}}),
    .coeff(coeff),
    .post_add(post_add),
    .din_valid(din_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);

reg [4*DIN_WIDTH-1:0] din_r=0;
always@(posedge clk)begin
    din_r <= {din_r[0+:3*DIN_WIDTH], din};
end

assign tap_delay = din_r[4*DIN_WIDTH-1-:DIN_WIDTH];


endmodule
