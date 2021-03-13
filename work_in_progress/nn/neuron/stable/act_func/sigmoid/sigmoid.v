`default_nettype none

module sigmoid #(
    parameter OUT_WIDTH = 16,
    parameter OUT_INT = 1,
    parameter IN_WIDTH = 10,
    parameter IN_INT = 4,
    parameter FILENAME="sigmoid_hex.mem"
) (
    input clk,
    input [IN_WIDTH-1:0] din,
    input din_valid,
    output [OUT_WIDTH-1:0] dout,
    output dout_valid
);

    reg [OUT_WIDTH-1:0] mem [2**IN_WIDTH-1:0];
    reg [OUT_WIDTH-1:0] dout_r=0;
    reg valid_r=0;

    initial begin
        $readmemh(FILENAME, mem);
    end
    
    always@(posedge clk)begin
        if(din_valid)begin
            dout_r <= mem[din];     
        end
    end

    always@(posedge clk)begin
        if(din_valid)
            valid_r <= 1;
        else
            valid_r <=0;
    end
    
    assign dout = dout_r;
    assign dout_valid = valid_r;

endmodule 
