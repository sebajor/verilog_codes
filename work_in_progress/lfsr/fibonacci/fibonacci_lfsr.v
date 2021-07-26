`default_nettype none

module fibonacci_lfsr #(
    parameter DATA_WIDTH = 8,
    parameter POLY = 8'b00001001
) (
    input wire clk,
    input wire en,
    input wire rst,
    input wire [DATA_WIDTH-1:0] seed,
    output wire [DATA_WIDTH-1:0] dout
);

reg [DATA_WIDTH-1:0] lfsr =0;

always@(posedge clk)begin
    if(rst)begin
        lfsr <= seed;
    end
    else if(en)begin
        lfsr[DATA_WIDTH-2:0] <= lfsr[DATA_WIDTH-1:1];
        lfsr[DATA_WIDTH-1] <= ^(lfsr[DATA_WIDTH-1:0] & POLY);
    end
end

assign dout = lfsr;

endmodule
