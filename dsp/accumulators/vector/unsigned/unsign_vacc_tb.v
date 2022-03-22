`default_nettype none
`include "unsign_vacc.v"

module unsign_vacc_tb #(
    parameter DIN_WIDTH = 16,
    parameter VECTOR_LEN = 64,
    parameter DOUT_WIDTH = 32
) (
    input wire clk,
    input wire new_acc,
    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,
    output wire [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);

unsign_vacc #(
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

reg [31:0] counter=0;
always@(posedge clk)begin
    if(dout_valid)
        counter <= counter+1;
end

endmodule
