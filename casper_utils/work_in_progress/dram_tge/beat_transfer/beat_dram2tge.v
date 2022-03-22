`default_nettype none
`include "dram2tge.v"

// we have 2**25*288 bits to send in 64 bit words ie we need 9*2**24 transactions
// if we use a 1024 pkt size that is 9*2**14 pkts.
//
//

module beat_dram2tge #(
    parameter DRAM_MAX_ADDR = 2**12

) (
    input wire clk,
    input wire ce, 
    //control signals
    input wire en,
    input wire rst,
    input wire tge_pkt_size,
    input wire idle_time,
    
    //dram signals
    output wire [31:0] dram_addr,
    input wire [287:0] dram_data,
    input wire dram_valid,

    //tge signals
    output wire [63:0] tge_data,
    output wire tge_valid,
    output wire tge_eof
);

//The fsm ask the dram for two word, wait for the dram response,
//reinterpert those 288*2 in 64 bit words and send them to the tge
//

localparam IDLE = 2'd0,
           READ_DRAM = 2'd1,
           WRITE_TGE= 2'd2,
           FINISH = 2'd3;

reg [1:0] state=0, next_state=0;

reg recv_dram=0;                //dram send the 2 words
reg write_tge=0;                //the words are written into the tge
reg [31:0] tge_counter=0;       //counts how many words have been written

reg [31:0] tge_pkt_counter=0;   //count the current pkt words, to add the eof
reg [4:0] tge_words=0;          //count the current words written, to change states


always@(posedge clk)begin
    if(rst)
        state <= IDLE;
    else
        state <= next_state;
end

always@(*)begin
    case(state)
        IDLE:begin
            if(en & ~finish)    next_state = READ_DRAM;
            else                next_state = IDLE;
        end
        READ_DRAM:begin
            if(recv_dram)   next_state = WRITE_TGE;
            else            next_state = READ_DRAM;
        end
        WRITE_TGE:begin
            if(tge_words == 8)  next_state = IDLE;
            else                next_state = WRITE_TGE;
        end
    endcase
end



always@(posedge clk)begin
    if(rst)begin


    end
    else begin
        case(state)
            IDLE:begin
                

            end
            READ_DRAM:begin


            end
            WRITE_TGE:begin

            end
        endcase
    end
end



module dram2tge (
    input wire clk,
    input wire rst,
    input wire en,
    
    input wire [287:0] dram_data,
    input wire dram_valid,
    output wire dram_request,
    input wire dram_ready,    //~empty

    output wire [63:0] tge_data,
    output wire tge_data_valid
);



















