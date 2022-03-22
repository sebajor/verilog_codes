`default_nettype none

/* This module converts the 288 dram words into the 64 bits tge words
    we need 2 cycles to complete a read translation and 9 cycles to complete 
    the write into the tge.. So we introduce a 7 cycle bubble.
*/

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

/*  
    1, dat0 <= din[0+:64]; dat1 <= din[64+:64]; dat2 <= din[128+:64]; dat3 <= din[192+:64]
       dat4[31:0] <= din[256+:32]
    2, dat4[32+:32] <= din[0+:32]; dat5<=din[32+:64]; dat6 <= din[96+:64]; dat7[160+:64]
       dat8[224+:64]
*/

localparam IDLE = 2'b00,
           READING = 2'b1,
           WRITING = 2'b1;

reg r_state=0, r_next_state=0;
reg w_state=0, w_next_state=0;
reg  r_counter=0;
reg [3:0] w_counter=0;

always@(posedge clk)begin
    if(rst) begin
        r_state <= IDLE;
        w_state <= IDLE;
    end
    else begin
        r_state <= r_next_state;
        w_state <= w_next_state;
    end
end

//read side
//read side
always@(*)begin
    case(r_state)
        IDLE: begin
            if((w_state==IDLE) & en & dram_ready)    r_next_state = READING;
            else                        r_next_state = IDLE;
        end
        READING:begin
            //if(r_counter==1)    r_next_state = IDLE;
            if(r_counter==1)    r_next_state = IDLE;
            else                r_next_state = READING;
        end
    endcase
end

//write side
always@(*)begin
    case(w_state)
        IDLE:begin
            if((r_state==READING) & r_counter!=0)   w_next_state = WRITING;
            else                                    w_next_state = IDLE;
        end
        WRITING:begin
            if(w_counter==8)    w_next_state = IDLE;
            else                w_next_state = WRITING;
        end
    endcase
end


//dram read
reg [63:0] dat0=0,dat1=0,dat2=0,dat3=0,dat4=0,dat5=0,dat6=0,dat7=0,dat8=0;

always@(posedge clk)begin
    if(rst)
        r_counter <=0;
    else if(dram_valid & (r_state==READING))
        r_counter <= r_counter+1;
    else
        r_counter <=0;
end

always@(posedge clk)begin
    if(dram_valid & r_state==READING)begin
        case(r_counter)
            0:begin
                dat0 <= dram_data[0+:64]; 
                dat1 <= dram_data[64+:64]; 
                dat2 <= dram_data[128+:64]; 
                dat3 <= dram_data[192+:64];
                dat4[31:0] <= dram_data[256+:32];
            end
            1:begin
                dat4[32+:32] <= dram_data[0+:32]; 
                dat5 <=dram_data[32+:64]; 
                dat6 <= dram_data[96+:64]; 
                dat7 <= dram_data[160+:64];
                dat8 <= dram_data[224+:64];
            end
        endcase
    end
end


//writing side
reg tge_out_valid =0, tge_valid=0;
always@(posedge clk)begin
    tge_valid <= tge_out_valid;
    if(rst)begin
        w_counter <=0;
        tge_out_valid <= 0;
    end
    else if(w_state==READING)begin
        tge_out_valid <= 1;
        w_counter <= w_counter+1;
    end
    else begin
        w_counter <=0;
        tge_out_valid <=0;
    end
end

reg [63:0] tge_out=0;
always@(posedge clk)begin
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

assign tge_data = tge_out;
assign tge_data_valid = tge_out_valid;

assign dram_request = (r_state ==READING) & (r_counter!=1) & ~rst;

endmodule 
