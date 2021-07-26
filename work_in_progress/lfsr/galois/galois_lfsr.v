`default_nettype none

module galois_lfsr #(
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
        if(lfsr[0])begin
            //in this case the parity will change
            lfsr <= {1'b0, lfsr[DATA_WIDTH-1:1]} ^ POLY;
        end
        else begin
            lfsr <= {1'b0, lfsr[DATA_WIDTH-1:1]};
        end
    end
end

assign dout = lfsr;

endmodule
