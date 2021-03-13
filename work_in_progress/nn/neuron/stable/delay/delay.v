`default_nettype none

// parametrizable delay using a shift register

module delay #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 4
) (
    input clk,
    input [DATA_WIDTH-1:0] din,
    output [DATA_WIDTH-1:0] dout
);
    genvar i;
    generate 
        for(i=0;i<DEPTH; i=i+1)begin: loop
            reg [DATA_WIDTH-1:0] d_din;
            if(i==0)begin
                always@(posedge clk)begin
                    d_din <= din;
                end
            end
            else begin
                always@(posedge clk)
                    d_din <= loop[i-1].d_din;
            end
        end
    endgenerate     

    assign dout = loop[DEPTH-1].d_din;

endmodule
