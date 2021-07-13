`default_nettype none
`define __GOLD_INIT__
//`define __SIM__
/*
*This fsm detects a pattern in an uart interface
*in this scheme the important value is gven after a known set of symbols
*/

module pattern_search #(
    parameter N_BITS = 8,
    parameter PATTERN_SIZE = 10,    //pattern size
    parameter INFO_SIZE = 2,
    parameter MEM_FILE ="gold_hex.mem" //the file is in hex!
) (
    input wire clk,
    input wire rst,
    //uart input
    input [N_BITS-1:0] char_in,
    input char_valid,
    
    //if you want to modify the golden word
    input [N_BITS-1:0] golden_word,
    input golden_word_valid,
    input [$clog2(PATTERN_SIZE)-1:0] golden_word_index,

    output [N_BITS-1:0] info_data,
    output info_valid//,
    //output reg [N_BITS-1:0] actual_gold
);

    reg [N_BITS-1:0] gold [PATTERN_SIZE-1:0];
    //initialize or charge the pattern to search for
    
    `ifdef __GOLD_INIT__
        initial begin
            $readmemh(MEM_FILE, gold); 
        end
    `endif

    always@(posedge clk)begin
        if(golden_word_valid)begin
            gold[golden_word_index] <= golden_word;
        end
    end
    
    
    //reg [$clog2(PATTERN_SIZE)-1:0] index_reading={$clog2(PATTERN_SIZE){1'b1}};
    reg [$clog2(PATTERN_SIZE)-1:0] index_reading=0;
    //carefull! if pattern size is the exact power of two this wouldnt work good
    reg pattern_found=0;

    //reading pointer evolution
    /*
    //*debug only
    always@(posedge clk)begin
        actual_gold <= gold[index_reading];
    end
    */
    //here end the debugging
    //consider a change of names!!!!
    //
    always@(posedge clk)begin
        if(rst)begin
            index_reading <=0;
        end
        else begin
            if(char_valid)begin
                //this way to read the data takes 2 cycles!
                //in uart doesnt matter..but look out!
                if(gold[index_reading] == char_in)
                    index_reading <= index_reading+1;
                else
                    index_reading <= 0;
            end
            else begin
                index_reading <= index_reading;
            end
        end
    end
    
    always@(posedge clk)begin
        if(rst)
            pattern_found <=0;
        else begin
            if(index_reading==PATTERN_SIZE)   //check!
                pattern_found <= 1;
            else
                pattern_found <= pattern_found;
        end
    end
  


    //now we had found the pattern, the next values are the data
    reg [$clog2(INFO_SIZE):0] index_info=0;
    reg r_info_valid = 0;
    reg [N_BITS-1:0] r_info_data=0;
    always@(posedge clk)begin
        if(rst)begin
            index_info<=0;
            r_info_valid <=0;
        end
        else begin
            if(pattern_found & char_valid)begin
                if(index_info < INFO_SIZE) begin
                    r_info_valid<=1;
                    r_info_data <= char_in;
                    index_info <= index_info +1;
                end
                else begin
                    r_info_valid <=0;
                    index_info <= index_info;
                    r_info_data<= r_info_data;
                end
            end
            else begin
                r_info_valid <= 0;
                index_info <= index_info;
                r_info_data <= r_info_data;
            end
        end
    end

    assign info_valid = r_info_valid;
    assign info_data = r_info_data;

`ifdef __SIM__
    initial begin
        $dumpfile("sim.vcd");
        $dumpvars(1, pattern_search);
    end
`endif

endmodule
