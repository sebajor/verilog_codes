`default_nettype none
`include "mandelbrot_line.v"

module mandelbrot_line_tb #(
    parameter BIT_WIDTH = 32,
    parameter BIT_HEIGHT = 16,
    parameter DIN_WIDTH = 32,
    parameter DIN_POINT = 12,
    parameter N_COMP = 4,
    parameter LINE_INDEX =0
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
    output wire [DIN_WIDTH-1:0] dout,
    input wire [$clog2(BIT_WIDTH)-1:0] cx, 
    input wire [$clog2(BIT_HEIGHT)-1:0] cy,
    output wire line_rdy
);

mandelbrot_line #(
    .BIT_WIDTH(BIT_WIDTH),
    .BIT_HEIGHT(BIT_HEIGHT),
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .N_COMP(N_COMP),
    .LINE_INDEX(LINE_INDEX)
) mandelbrot_line_inst (
    .clk(clk),
    .rst(rst),
    .x_i(x_i),
    .x_step(x_step),
    .y_i(y_i),
    .y_step(y_step),
    .iters(iters),
    .c_re(c_re),
    .c_im(c_im),
    .dout(dout),
    .cx(cx), 
    .cy(cy),
    .line_rdy(line_rdy)
);

endmodule
