`default_nettype none
`include "acc_control.v"

module acc_control_tb #(
    parameter CHANNEL_ADDR= 7   //2**
) (
    input wire clk,
    input wire ce,
    input wire sync_in,
    input wire [31:0] acc_len,
    input wire rst,
    output wire new_acc
);

acc_control #(
    .CHANNEL_ADDR(CHANNEL_ADDR)
) acc_control_inst (
    .clk(clk),
    .ce(ce),
    .sync_in(sync_in),
    .acc_len(acc_len),
    .rst(rst),
    .new_acc(new_acc)
);

reg [31:0] counter =0;
always@(posedge clk)begin
    if(new_acc)
        counter <=0;
    else
        counter <= counter+1;

end


endmodule
