`default_nettype none
`include "iterative_sqrt.v"

module iterative_sqrt_tb #(
    parameter DIN_WIDTH = 10,
    parameter DIN_POINT = 6
) (
    input wire clk,
    output wire busy,
    input wire din_valid,
    input wire [DIN_WIDTH-1:0] din,
    output wire [DIN_WIDTH-1:0] dout,
    output wire [DIN_WIDTH-1:0] reminder,
    output wire dout_valid
);


iterative_sqrt #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT)
) iterative_sqrt (
    .clk(clk),
    .busy(busy),
    .din_valid(din_valid),
    .din(din),
    .dout(dout),
    .reminder(reminder),
    .dout_valid(dout_valid)
);

reg [31:0] count=0;
always@(posedge clk)begin
    if(~busy)
        count <=0;
    else
        count <= count+1;

end

endmodule
