`default_nettype none
`include "signed_vacc.v"

module signed_vacc_tb #(
    parameter DIN_WIDTH = 16,
    parameter VECTOR_LEN = 64,
    parameter DOUT_WIDTH = 32
) (
    input wire clk,
    input wire new_acc,
    input wire signed [DIN_WIDTH-1:0] din,
    input wire din_valid,
    output wire signed [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);

wire test;
signed_vacc #(
    .DIN_WIDTH(DIN_WIDTH),
    .VECTOR_LEN(VECTOR_LEN),
    .DOUT_WIDTH(DOUT_WIDTH)
) signed_vacc_inst  (
    .clk(clk),
    .new_acc(new_acc),
    .din(din),
    .din_valid(din_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);
reg [31:0] count=0;
always@(posedge clk)begin
    if(dout_valid)begin
        if(count == (VECTOR_LEN-1))
            count <=0;
        else
            count <= count+1;
    end
end

reg [5:0] count2=0;
always@(posedge clk)begin
    if(new_acc)
        count2 <=0;
    else
        count2 <= count2+1;
end

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end

endmodule
