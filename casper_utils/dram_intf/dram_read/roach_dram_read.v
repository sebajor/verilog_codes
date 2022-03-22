`default_nettype none

/*
*   Author: Sebastian Jorquera
*   
*   This module read the roach dram using burst size. To begin a read burst
*   generate a rising edge in the next_burst input, when the burst read request
*   is ready the signal burst_done goes high.
*   There are cases where you need to repeat the same burst.At the begining of
*   each burst we save the starting address, so if you want to repeat it when 
*   the burst done is in high you have to generate a rising edge in the
*   repeat_burst signal and then issue a next_burst.
*   When the whole dram is read, the finish signal goes up.
*
*/

module roach_dram_read #(
    parameter ADDR_WIDHT = 25
) (
    input wire clk,
    input wire rst,

    input wire read_en,
    input wire [31:0] burst_len,    //32 words is the minimum recommended
    input wire next_burst,          //rising edge starts a reading of burst_len
    input wire repeat_burst,        
    output wire burst_done,
    output wire finish,
    

    //goes to input dram
    output wire [ADDR_WIDHT-1:0] dram_addr,
    output wire rwn, 
    output wire cmd_valid,

    //goes to output dram
    input wire rd_ack,  //dont care
    input wire cmd_ack, //dont care
    input wire [287:0] dram_data,
    input wire rd_tag,  //dont care
    input wire rd_valid,

    //goes to any other module
    output wire [287:0] read_data,
    output wire read_valid
);

/*
    To read from the dram:
    1) set rwn at high
    2) toggle the cmd_valid from 0-1
    3) keep the address while toggle
    4) After an undetermined number of cycles the dram will respond and 
       there will be a high value in the rd_valid. The data will be in order
       but again its the same value for two cycles.
    
    For performance is better to read in burst (to take advantage of the banks)
*/

//DRAM inputs


localparam IDLE = 0,
           READING =1;

reg state=0, next_state=0;
always@(posedge clk)begin
    //next_burst_r <= next_burst;
    if(rst)
        state <= IDLE;
    else
        state <= next_state;
end

always@(*)begin
    case(state)
        IDLE:begin
            if((next_burst & ~next_burst_r) & ~finish_r)  next_state = READING;
            else                            next_state = IDLE;
        end
        READING:begin
            if((burst_count == ((burst_len<<1))) | finish_r)  next_state = IDLE;
            else                                next_state = READING;
        end
    endcase
end

reg [ADDR_WIDHT+1:0] addr_count=0, addr_count2=0;
reg [31:0] burst_count=0;
reg next_burst_r=0;
reg finish_r=0;

reg prev_state=0;
always@(posedge clk)begin
    prev_state <= state;
    if(rst)
        addr_count2 <=0;
    else if((prev_state==IDLE) & (state==READING) & !repeat_burst)
        addr_count2 <= addr_count;
end

always@(posedge clk)begin
    if(rst)begin
        addr_count<=0;//{(ADDR_WIDHT+2){1'b1}};
        burst_count <= {(32){1'b1}};
        next_burst_r <=0;
    end
    else begin
        next_burst_r <= next_burst;
        case(state)
            IDLE:begin
                burst_count <= {(32){1'b1}};
                if(repeat_burst)
                    addr_count <= addr_count2;
            end
            READING:begin
                burst_count <= burst_count+1;
                addr_count <= addr_count+1;
            end
        endcase
    end
end

assign dram_addr = addr_count[ADDR_WIDHT:1];
assign cmd_valid = (state==READING) & addr_count[0];    //check... otherwise use a reg in the state case
assign rwn = read_en;

//DRAM outputs

reg rd_valid_r=0;
always@(posedge clk)begin
    if(rst)
        rd_valid_r <=0;
    if(rd_valid)
        rd_valid_r <= rd_valid_r+1;
end

assign read_data = dram_data;   //check.. i think it needs a delay
assign read_valid = read_en & rd_valid_r;   //check in hw!!!

always@(posedge clk)begin
    if(rst)
        finish_r <= 0;
    else if((&addr_count[ADDR_WIDHT:0]) & ~addr_count[ADDR_WIDHT+1])
        finish_r <=1;
end

//

//To other modules
assign finish = finish_r | ((&addr_count[ADDR_WIDHT:0]) & ~addr_count[ADDR_WIDHT+1]) ;
assign burst_done = (state==IDLE);

endmodule
