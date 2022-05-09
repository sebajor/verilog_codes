`default_nettype none

/*
*   Author: Sebastian Jorquera
*   This module search for an ascii pattern and after found it start to collect
*   the data that is after it.
*   The input data comes one byte a the time 
*   
*/


module pattern_search #(
    parameter PATTERN_LEN = 11,
    parameter PATTERN = "hello world",
    parameter INFO_LEN = 7//14
) (
    input wire clk,
    input wire rst,

    input wire [7:0] din,
    input wire  din_valid,

    output wire pattern_found,
    output wire [7:0] info_data,
    output wire info_valid
);

reg [7:0] pattern [PATTERN_LEN-1:0];
initial begin
    for(integer i=0; i<PATTERN_LEN; i=i+1)begin
        pattern[i] = ((PATTERN>>i)&8'hff);
    end
end

reg [$clog2(PATTERN_LEN)-1:0] index_read=0;
reg pattern_found_r=0;

always@(posedge clk)begin
    if(rst)
        index_read <=0;
    else if(din_valid)begin
        if(pattern[index_read] == din)
            index_read <= index_read+1;
        else
            index_read <= 0;
    end
end

always@(posedge clk)begin
    if(rst)
        pattern_found_r <=0;
    else if(index_read== PATTERN_LEN)
        pattern_found_r <= 1; 
end

//after finding the pattern the next values are data
reg [$clog2(INFO_LEN)-1:0] index_info=0;
reg info_valid_r=0;
reg [7:0] info_data_r=0;

always@(posedge clk)begin
    if(rst)begin
        index_info <=0;
        info_valid_r <=0;
    end
    else if(pattern_found & din_valid)begin
        if(index_info < INFO_LEN)begin
            info_valid_r <= 1;
            info_data_r <= din;
            index_info <= index_info+1;
        end
        else
            info_valid_r <=0;
    end
end

assign info_data= info_data_r;
assign info_valid = info_valid_r;
assign pattern_found = pattern_found_r;
    


endmodule
