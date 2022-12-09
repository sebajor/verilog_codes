`default_nettype none

module delay #(
    parameter DATA_WIDTH = 32,
    parameter DELAY_VALUE = 2
) (
    input wire clk,
    input wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout
);

wire [31:0] debug = DELAY_VALUE;

generate 
    if(DELAY_VALUE==0)begin
        assign dout =  din;
    end
    else if(DELAY_VALUE==1)begin
        reg [DATA_WIDTH-1:0] data_r=0;
        assign dout = data_r;
        always@(posedge clk)begin
            data_r <= din;
        end
    end
    else begin
        reg [DATA_WIDTH*DELAY_VALUE-1:0] data_r =0;
        assign dout = data_r[(DELAY_VALUE-1)*DATA_WIDTH+:DATA_WIDTH];
        always@(posedge clk)begin
            data_r <= {data_r[(DELAY_VALUE-1)*DATA_WIDTH-1:0], din};
        end
    end
endgenerate

endmodule
