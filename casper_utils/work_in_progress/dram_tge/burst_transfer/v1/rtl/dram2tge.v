`default_nettype none

/* This module converts the 288 dram words into the 256 tge words.
    we need 8 cycles to complete a read translation and 9 cycles to complete 
    the read, so at minimum we introduce 1 bubble
*/

module dram2tge (
    input wire clk,
    input wire rst,
    input wire en,
    
    input wire [287:0] dram_data,
    input wire dram_valid,
    output wire dram_request,
    input wire dram_ready,    //~empty

    output wire [255:0] tge_data,
    output wire tge_data_valid
);

/*  1, dat0[255:0]   <= din[255:0]; dat1[31:0]  <= din[287:255];
    2, dat1[255:32]  <= din[223:0]; dat2[63:0]  <= din[287:224];
    3, dat2[255:64]  <= din[191:0]; dat3[95:0]  <= din[287:192];
    4, dat3[255:96]  <= din[159:0]; dat4[127:0] <= din[287:160];
    5, dat4[255:128] <= din[127:0]; dat5[159:0] <= din[287:128];
    6, dat5[255:160] <= din[95:0];  dat6[191:0] <= din[287:96];
    7, dat6[255:192] <= din[63:0];  dat7[223:0] <= din[287:64];
    8, dat7[255:224] <= din[31:0];  dat8[255:0] <= din[287:32];
*/
localparam  IDLE = 2'b00,
            READING = 2'b1,
            WRITING = 2'b1;

reg r_state=0, r_next_state=0;
reg w_state=0, w_next_state=0;
reg [2:0] r_counter=0;
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
always@(*)begin
    case(r_state)
        IDLE: begin
            if((w_state==IDLE) & en & dram_ready)    r_next_state = READING;
            else                        r_next_state = IDLE;
        end
        READING:begin
            if(r_counter==7)    r_next_state = IDLE;
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

//read side
reg [255:0] dat0=0, dat1=0, dat2=0, dat3=0,
            dat4=0, dat5=0, dat6=0, dat7=0,
            dat8=0;

always@(posedge clk)begin
    if(rst)
        r_counter <=0;
    else if(dram_valid & r_state==READING)
        r_counter <= r_counter+1;
    else
        r_counter <=0;
end

always@(posedge clk)begin
    if(dram_valid & r_state==READING)begin
        case(r_counter)
            0:begin
                dat0[255:0] <= dram_data[255:0]; 
                dat1[31:0]  <= dram_data[287:256];
            end
            1:begin
                dat1[255:32]<= dram_data[223:0];
                dat2[63:0]  <= dram_data[287:224];
            end
            2:begin
                dat2[255:64]<= dram_data[191:0];
                dat3[95:0]  <= dram_data[287:192];
            end
            3:begin
                dat3[255:96] <= dram_data[159:0];
                dat4[127:0] <= dram_data[287:160];
            end
            4:begin
                dat4[255:128] <= dram_data[127:0];
                dat5[159:0] <= dram_data[287:128];
            end
            5:begin
                dat5[255:160] <= dram_data[95:0];
                dat6[191:0] <= dram_data[287:96];
            end
            6:begin
                dat6[255:192] <= dram_data[63:0];
                dat7[223:0] <= dram_data[287:64];
            end
            7:begin
                dat7[255:224] <= dram_data[31:0];
                dat8[255:0] <= dram_data[287:32];
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

reg [255:0] tge_out=0;
//check sync!
always@(posedge clk)begin
    case(w_counter)
        0:  tge_out = dat0;
        1:  tge_out = dat1;
        2:  tge_out = dat2;
        3:  tge_out = dat3;
        4:  tge_out = dat4;
        5:  tge_out = dat5;
        6:  tge_out = dat6;
        7:  tge_out = dat7;
        8:  tge_out = dat8;
    endcase
end

assign tge_data = tge_out;
assign tge_data_valid = tge_out_valid; //(w_state == WRITING)
//assign dram_request = (r_state == IDLE) & (w_state==IDLE) & (~rst);
//dram req must access to 9 addresses 
assign dram_request = (r_state == READING)& (r_counter<7) & ~rst;


endmodule
