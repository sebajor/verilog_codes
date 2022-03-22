`default_nettype none

/* This module converts the 288 dram words into the 64 bits tge words
    we need 2 cycles to complete a read translation and 9 cycles to complete 
    the write into the tge.. So we introduce a 7 cycle bubble.
*/

module dram2tge #(
    parameter DRAM_ADDR = 25
) (
    input wire clk,
    input wire rst,
    input wire en,
        
    input wire [31:0] tge_wait,
    input wire [31:0] tge_pkt, 
    input wire [31:0] tge_total_pkts,

    output wire dram_request,
    output wire [31:0] dram_addr,
    
    input wire [287:0] dram_data,
    input wire dram_valid,

    output wire [63:0] tge_data,
    output wire tge_data_valid,
    output wire tge_eof,

    output wire finish
);

localparam IDLE = 2'b00,
            READ = 2'b01,
            WAIT = 2'b10,
            WRITE = 2'b11;


reg [1:0] state =0, next_state=0;
reg [2:0] r_counter=0;
reg [1:0] resp_counter=0;
reg [3:0] w_counter=0;
reg [31:0] dram_addr_r=0;


reg tge_flag=0;

always@(posedge clk)begin
    if(rst)
        state <= IDLE;
    else
        state <= next_state; 
end


always@(*)begin
    case(state)
        IDLE:begin
            if(en & ~finish &~tge_flag)    next_state = READ;
            else                next_state = IDLE;
        end
        READ:begin
            next_state = WAIT;
        end
        WAIT:begin
            if(resp_counter==2)       next_state = WRITE;
            else                    next_state = WAIT;
        end
        WRITE:begin
            if(w_counter == 8)  next_state = IDLE;
            else                next_state = WRITE;
        end
    endcase
end

//ask for the data 
always@(posedge clk)begin
    if(state==IDLE)begin
        r_counter <=0;
    end
    else if(r_counter!=5)begin
        r_counter<= r_counter+1;
    end
end

always@(posedge clk)begin
    if(rst)begin
        dram_addr_r <=0;
    end
    //else if((state!= IDLE)&&(r_counter!=5)&&(dram_addr!= (2**DRAM_ADDR-1)))
    if(dram_request)
        dram_addr_r <=dram_addr_r+1;
    else
        dram_addr_r <= dram_addr_r;
end

assign dram_addr = {1'b0, dram_addr_r[31:1]};
assign dram_request = (state==WAIT) & (r_counter!=5);

//wait the response from the dram 

always@(posedge clk)begin
    if(state==WAIT)begin
        if(dram_valid)
            resp_counter <= resp_counter+1;
    end
    else
        resp_counter <=0;
end

//obtain the data from the dram..
reg [63:0] dat0=0,dat1=0,dat2=0,dat3=0,dat4=0,dat5=0,dat6=0,dat7=0,dat8=0;
always@(posedge clk)begin
    if(dram_valid & (state==WAIT))begin
        case(resp_counter)
            0:begin
                dat0 <= dram_data[0+:64]; 
                dat1 <= dram_data[64+:64]; 
                dat2 <= dram_data[128+:64]; 
                dat3 <= dram_data[192+:64];
                dat4[31:0] <= dram_data[256+:32];
            end
            2:begin
                dat4[32+:32] <= dram_data[0+:32]; 
                dat5 <=dram_data[32+:64]; 
                dat6 <= dram_data[96+:64]; 
                dat7 <= dram_data[160+:64];
                dat8 <= dram_data[224+:64];
            end
        endcase
    end    
end

//write
reg [31:0] pkt_counter=0, tge_counter=0;
reg [63:0] tge_out=0;
reg tge_valid = 0;

assign tge_data = tge_out;
assign tge_data_valid = tge_valid;

always@(posedge clk)begin
    if(state==WRITE)begin
        tge_valid <=1;
        w_counter <= w_counter+1;
        case(w_counter)
            0: tge_out = dat0;
            1: tge_out = dat1;
            2: tge_out = dat2;
            3: tge_out = dat3;
            4: tge_out = dat4;
            5: tge_out = dat5;
            6: tge_out = dat6;
            7: tge_out = dat7;
            8: tge_out = dat8;
        endcase
    end
    else begin
        w_counter <=0;
        tge_valid <=0;
    end
end

//pkt counter
always@(posedge clk)begin
    if(rst)begin
        pkt_counter <= 0;
        tge_counter <= 0;
    end
    else if(state==WRITE && ~finish)begin
        tge_counter <= tge_counter+1;
        if(pkt_counter==(tge_pkt-1))
            pkt_counter <=0;
        else
            pkt_counter <= pkt_counter+1;
    end
end

reg last_eof=0;
reg finish_r=0;
always@(posedge clk)begin
    if(rst)begin
        finish_r<=0;
        last_eof <=0;
    end 
    else begin
        last_eof <= finish_r;
        if(tge_counter==(tge_total_pkts-1))    //check!!!
            finish_r <= 1;
    end
end

//eof and finish signals
assign tge_eof = ((pkt_counter == (tge_pkt-1)) & (state==WRITE)); //| (finish & ~last_eof);
assign finish = finish_r;


reg [31:0] wait_counter=0;
always@(posedge clk)begin
    last_eof <= finish;
    if(rst)begin
        wait_counter <=0;
        tge_flag<=0;
    end
    else if(tge_eof)
        tge_flag <=1;
    else if(state==IDLE && tge_flag)begin
        if(wait_counter==(tge_wait-1))begin
            wait_counter <= 0;
            tge_flag <=0;
        end
        else
            wait_counter <= wait_counter+1;
    end
end



endmodule
