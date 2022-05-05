`default_nettype none

/*
*   Author: Sebastian Jorquera
*   This module generates a pulse after a certain
*   amount of cycles. Typically we use it to 
*   start a new accumlation in spectrometers
*   
*/

module acc_control #(
    parameter CHANNEL_ADDR= 7   //2**
) (
    input wire clk,
    input wire ce,
    input wire sync_in,
    input wire [31:0] acc_len,
    input wire rst,
    output wire new_acc
);
reg en=0, en_r=0;
always@(posedge clk)begin
    en_r <=en;
    if(rst)
        en <=0;
    else if(sync_in)
        en <= 1;
end

reg [31:0] counter =0;
always@(posedge clk)begin
    if(en & ~en_r)
        counter <=1;
    else if(counter ==(acc_len<<CHANNEL_ADDR))
        counter <=1;
    else
        counter <= counter+1;
end

assign new_acc = (counter==(acc_len<<CHANNEL_ADDR));

endmodule
