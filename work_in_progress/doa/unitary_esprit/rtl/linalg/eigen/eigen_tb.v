`default_nettype none
`include "eigen.v"

module eigen_tb #(
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
    output wire signed [DOUT_WIDTH-1:0] eigen1_y, eigen2_y, eigen_x,
    //the correct eigen value is eigen_x/eigen_y, but the output of this
    //module goes into a arctan so we are happy with that :)
    output wire dout_valid
);

eigen #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .SQRT_IN_WIDTH(SQRT_IN_WIDTH), 
    .SQRT_IN_POINT(SQRT_IN_POINT),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT)
) eigen_inst(
    .clk(clk),
    .r11(r11),
    .r22(r22),
    .r12(r12),
    .din_valid(din_valid),
    .lamb1(lamb1),
    .lamb2(lamb2),
    .eigen1_y(eigen1_y),
    .eigen2_y(eigen2_y),
    .eigen_x(eigen_x),
    .dout_valid(dout_valid)
);

reg [3:0] count=0;
reg [15*4-1:0] count_delay=0;
always@(posedge clk)begin
    if(din_valid)begin
        count <= count+1;
        count_delay <= {count_delay[14*4-1:0], count};
    end
end

wire [3:0] addr = count_delay[15*4-1:14*4];


initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end

endmodule
