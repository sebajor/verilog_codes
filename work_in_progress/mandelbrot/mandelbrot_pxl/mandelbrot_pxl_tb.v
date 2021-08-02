`default_nettype none
`include "mandelbrot_pxl.v"

module mandelbrot_pxl_tb #(
    parameter DIN_POINT = 12
)(
    input wire clk,
    input wire [31:0] x_init, y_init,
    input wire [31:0] c_re, c_im,
    input wire [31:0] iters,
    input wire din_valid,
    
    output wire busy,
    output wire [31:0] dout,
    output wire dout_valid
);



mandelbrot_pxl #(
    .DIN_POINT(12)
) mandelbort_pxl_inst (
    .clk(clk),
    .x_init(x_init),
    .y_init(y_init),
    .c_re(c_re),
    .c_im(c_im),
    .iters(iters),
    .din_valid(din_valid),
    .busy(busy),
    .dout(dout),
    .dout_valid(dout_valid)
);

reg [31:0] time_count=0;
always@(posedge clk)begin
    if(din_valid)
        time_count<=0;
    else
        time_count <= time_count+1;
end

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end

endmodule
