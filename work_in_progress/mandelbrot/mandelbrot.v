`default_nettype none


module mandelbrot #(
    parameter BIT_WIDTH = 640,
    parameter BIT_HEIGHT = 480
) (
    input wire clk,
    //parameters
    input wire signed [31:0] x_i,
    input wire [31:0] x_step,
    input wire signed [31:0] y_i,
    input wire [31:0] y_step,
    input wire [31:0] iters,
    input wire [31:0] c_re, c_im,
    input wire rst,

    //display ports
    output wire [31:0] dout,
    input wire [$clog2(BIT_WIDTH)-1:0] cx, 
    input wire [$clog2(BIT_HEIGHT)-1:0] cy
);

localparam INF = {1'b0, {31{1'b1}}};

reg [31:0] calc_x=0, calc_y=0;
reg [31:0] iter_count=0;
reg [$clog2(BIT_WIDTH)-1:0] pos_x=0;
reg [$clog2(BIT_HEIGHT)-1:0] pos_y=0;
reg flag=0;
always@(posedge clk)begin
    if(rst)begin
        flag <=0;
        pos_x <= x_i;
        pos_y <= y_i;
        calc_x<=0;
        calc_y<=0;
    end
    if(~flag)begin
        if((iter_count == iters) | (calc_x== INF) | (calc_y ==INF))begin
            //finish of the iteration for the current bit

        end
    end
end

endmodule
