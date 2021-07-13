`default_nettype none

//ADD A DELAY IN THE DATA LINE!!

//generate a sync pulse with sync_period period
//based on the typical casper implementation, sync_in comes before the 
//data, to be in perfect synchronization with the following data frames
//add a register into the data line or the sync_out will be placed in the
//first sample of the frame.
module sync_gen (
    input wire clk,
    input wire ce,
    input wire rst,
    input wire [31:0] sync_period,
    
    input wire sync_in,
    output wire sync_out
);
reg en_count=0;
always@(posedge clk)begin
    if(rst)
        en_count <= 0;
    else if(sync_in)
        en_count <= 1;
end

reg [31:0] counter=1;
reg sync_out_r=0;
always@(posedge clk)begin
    if(rst)begin
        counter <= 1;   //check!
        sync_out_r <=0;
    end
    else if(en_count)begin
        if(counter == sync_period)begin
            sync_out_r<= 1;
            counter <=1;
        end
        else begin
            sync_out_r <= 0;
            counter <= counter+1;
        end
    end
end

assign sync_out = sync_out_r;

endmodule
