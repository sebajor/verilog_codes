`default_nettype none

module adder #(
    parameter DIN_WIDTH = 10,
    parameter DATA_TYPE = "unsigned"
)(
    input wire clk,
    input wire [DIN_WIDTH-1:0] din0, din1,
    input wire din_valid,
    output wire [2*DIN_WIDTH-1:0] dout,
    output wire dout_valid
);
reg [2*DIN_WIDTH-1:0] dout_r=0;
reg dout_valid_r=0;
assign dout_valid = dout_valid_r;
assign dout = dout_r;
generate 
    if(DATA_TYPE=="signed")begin
        always@(posedge clk)begin
            dout_r <= $signed(din0)+$signed(din1);
            dout_valid_r <= din_valid;
        end
    end
    else begin 
        always@(posedge clk)begin
            dout_r <= $unsigned(din0)+$unsigned(din1);
            dout_valid_r <= din_valid;
        end
    end
endgenerate

endmodule
