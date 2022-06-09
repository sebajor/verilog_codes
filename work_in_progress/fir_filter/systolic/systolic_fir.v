`default_nettype none

module systolic_fir #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    parameter WEIGHT_WIDTH = 16,
    parameter WEIGHT_POINT = 14,
    parameter WEIGHT_SIZE = 32,
    parameter WEIGHT_FILE = "fir_weight.b",
    parameter DOUT_WIDTH = 32,  //this cast is after all the multpliyers
    parameter DOUT_POINT = 28
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din,
    input wire din_valid,

    output wire signed [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);

reg [WEIGHT_WIDTH-1:0] weight_mem [WEIGHT_SIZE-1:0];
initial begin
    $readmemb(WEIGHT_FILE, weight_mem);
end

genvar i;
localparam POST_ADD = DIN_WIDTH+WEIGHT_WIDTH+$clog2(WEIGHT_SIZE)+1;
localparam POST_POINT = DIN_POINT+WEIGHT_POINT;
generate
for(i=0; i<WEIGHT_SIZE; i=i+1)begin: tap_loop
    wire signed [POST_ADD-1:0] tap_out;
    wire tap_valid;
    wire signed [DIN_WIDTH-1:0] din_dly;
    
    if(i==0)begin
        systolic_tap #(
            .DIN_WIDTH(DIN_WIDTH),
            .DIN_POINT(DIN_POINT),
            .COEF_WIDTH(WEIGHT_WIDTH),
            .COEF_POINT(WEIGHT_POINT),
            .POST_ADD(POST_ADD)
        ) tap_inst  (
            .clk(clk),
            .din(din),
            .coeff(weight_mem[0]),
            .post_add({(POST_ADD){1'b0}}),
            .din_valid(din_valid),
            .dout(tap_out),
            .dout_valid(tap_valid),
            .tap_delay(din_dly)
        );
    end
    else begin
        systolic_tap #(
            .DIN_WIDTH(DIN_WIDTH),
            .DIN_POINT(DIN_POINT),
            .COEF_WIDTH(WEIGHT_WIDTH),
            .COEF_POINT(WEIGHT_POINT),
            .POST_ADD(POST_ADD)
        ) tap_inst  (
            .clk(clk),
            .din(tap_loop[i-1].din_dly),
            .coeff(weight_mem[i]),
            .post_add(tap_loop[i-1].tap_out),
            .din_valid(tap_loop[i-1].tap_valid),
            .dout(tap_out),
            .dout_valid(tap_valid),
            .tap_delay(din_dly)
        );
    end
end
endgenerate

signed_cast #(
    .DIN_WIDTH(POST_ADD),
    .DIN_POINT(POST_POINT),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT)
)signed_cast_inst (
    .clk(clk), 
    .din(tap_loop[(WEIGHT_SIZE-1)].tap_out),
    .din_valid(tap_loop[(WEIGHT_SIZE-1)].tap_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);

endmodule
