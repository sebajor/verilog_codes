`default_nettype none

/* sigmoid in a rom look up table 
 you need to first run the script sigmoid_gen.py
*/


module sigmoid #(
    parameter DOUT_WIDTH = 8,
    parameter DUOT_INT = 1,
    parameter DIN_WIDTH = 16,
    parameter DIN_INT = 4,
    parameter FILENAME = "sigmoid_hex.mem"
) (
    input wire clk,
    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,
    output wire [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);

reg [DOUT_WIDTH-1:0] mem [2**DIN_WIDTH-1:0];
reg [DOUT_WIDTH-1:0] dout_r=0;
reg valid_r = 0;

assign dout = dout_r;
assign dout_valid = valid_r;

initial begin
    $readmemh(FILENAME, mem);
end

always@(posedge clk)begin
    if(din_valid)
        dout_r <= mem[din]; 
end

always@(posedge clk)begin
    valid_r <= din_valid;
end

endmodule 
