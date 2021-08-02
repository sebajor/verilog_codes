`default_nettype none
`include "includes.v"

module mandelbrot_top #(
    parameter BIT_WIDTH = 200,//640,
    parameter BIT_HEIGHT = 200,//480,
    parameter DIN_WIDTH = 32,
    parameter DIN_POINT = 12,
    parameter N_COMP = 8,
    parameter TYPE = "BASIC"    //"BASIC" or "CUSTOM"

) (
    input wire clk,
    input wire rst,
    //parameters
    input wire signed [DIN_WIDTH-1:0] x_i,
    input wire [31:0] x_step,
    input wire signed [DIN_WIDTH-1:0] y_i,
    input wire [31:0] y_step,
    input wire [31:0] iters,
    input wire [DIN_WIDTH-1:0] c_re, c_im,

    //display ports
    output reg [31:0] dout,
    input wire [$clog2(BIT_WIDTH)-1:0] cx, 
    input wire [$clog2(BIT_HEIGHT)-1:0] cy,
    output wire rdy
);

wire [N_COMP-1:0] line_rdy;
wire [N_COMP*32-1:0] line_read;

genvar i;
generate 

for(i=0; i<N_COMP; i=i+1)begin: line_loop
mandelbrot_line #(
    .BIT_WIDTH(BIT_WIDTH),
    .BIT_HEIGHT(BIT_HEIGHT),
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .N_COMP(N_COMP),
    .LINE_INDEX(i),
    .TYPE(TYPE)
) line_gen (
    .clk(clk),
    .rst(rst),
    .x_i(x_i),
    .x_step(x_step),
    .y_i(y_i),
    .y_step(y_step),
    .iters(iters),
    .c_re(c_re),
    .c_im(c_im),
    .dout(line_read[32*i+:32]),
    .cx(cx), 
    .cy(cy),
    .line_rdy(line_rdy[i])
);
end
endgenerate

wire sub_addr = cy[$clog2(N_COMP)-1:0];

always@(*)begin
    dout = line_read[sub_addr*32+:32];
end
assign rdy = &line_rdy;

endmodule
