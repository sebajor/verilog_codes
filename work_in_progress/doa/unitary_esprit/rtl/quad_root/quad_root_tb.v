`include "quad_root.v"


module quad_root_tb #(
    parameter DIN_WIDTH = 8,
    parameter DIN_POINT = 7,
    parameter DOUT_WIDTH = 8,
    parameter DOUT_POINT = 7,
    parameter SQUARE_ALGO = "lut"   //type of implementation of the algorithm
) (
    input wire clk,
    
    input wire din_valid,
    input wire [DIN_WIDTH-1:0] b,
    input wire [DIN_WIDTH-1:0] c,

    output wire [DOUT_WIDTH-1:0] x1,
    output wire [DOUT_WIDTH-1:0] x2,
    output wire dout_valid
);

quad_root #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT),
    .SQUARE_ALGO(SQUARE_ALGO)
)quad_root_inst (
    .clk(clk),
    .din_valid(din_valid),
    .b(b),
    .c(c),
    .x1(x1),
    .x2(x2),
    .dout_valid(dout_valid)
);

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end

endmodule
