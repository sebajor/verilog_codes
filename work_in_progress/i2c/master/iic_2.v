`default_nettype none

/* Single master of i2c
in this implementation the lines are pulled up by an external source

Code made thinking in SCCB interface, ie at most support 
sent 3 words (dev addr+internal addr+ data) or sent 2 words and
receive one
*/

module iic_master #(
    parameter FPGA_CLK = 25_000_000,
    parameter IIC_CLK = 10_000
) (
    input wire clk,
    input wire rst,
    //control signals
    input wire start,
    input wire [31:0] ctrl,
    output wire [7:0] i2c_recv,
    output wire i2c_recv_valid,
    output wire error,
    //iic signal
    inout wire SCL,
    inout wire SDA
);
//clog2 definition
function integer clogb2;
    input [31:0] val;
    begin
        val = val-1;
        for(clogb2=0; val>0; clogb2=clogb2+1)
            val = val>>1;
    end
endfunction

localparam CLK_CYCLES = FPGA_CLK/IIC_CLK;
localparam t_start = 5*FPGA_CLK/1_000_000;    //4us is the minimun for start condition
localparam t_wait = CLK_CYCLES/8;   //time to wait after an ack
localparam t_stop = CLK_CYCLES/8;   // 
//line control
reg float_sda=1, float_scl=1;
wire sda_in, scl_in;

assign scl_in = SCL;
assign SCL = float_scl ? 1'bz:1'b0;
assign sda_in = SDA;
assign SDA = float_sda ? 1'bz:1'b0;

//control signals
reg [clogb2(CLK_CYCLES)-1:0] counter=0;
reg [5:0] index_counter=0;
reg [31:0] ctr_reg=0;

integer i,j,k;
always@(posedge clk)begin
    //ctr_reg[6:0] <= ctrl[0:6]; //this doesnt work :(
    for(i=0;i<7;i=i+1)begin
        ctr_reg[i] <= ctrl[6-i];
    end
    ctr_reg[7] <= ctrl[7];
    ctr_reg[8] <= 1'b1;
    //ctr_reg[16:9] <= ctrl[9:16];
    for(j=0; j<8;j=j+1)begin
        ctr_reg[j+9] <= ctrl[16-j];
    end
    ctr_reg[17]<= 1'b1;
    //ctr_reg[25:18 <= ctrl[17:25];
    for(k=0; k<8; k=k+1)begin
        ctr_reg[k+18] <= ctrl[25-k];
    end
    ctr_reg[26] <= 1'b1;
    ctr_reg[30:27] <= ctrl[30:27];
    ctr_reg[31] <= 1'b1;
end
/*
0-6: 7 bit slave address (msb is send first)
7: 0=write, 1=read
8: 1 to free the line
9-16: internal address of the slave
17; 1 to free the line
18:25: data to write
26: 1 to free the line
28: 1:no need the send third byte
27: in case of nack of the slave 0:stop 1:repeated start

*/

reg [7:0] recv = 0;
reg ack_r =0;
reg error_r=0, recv_valid=0;
reg [3:0] state=0, next_state=0;


assign error = error_r;
assign i2c_recv = recv;
assign i2c_recv_valid = recv_valid;

//states
localparam  IDLE =  4'b0000,
            START = 4'b0001,
            SEND =  4'b0010,
            ACK =   4'b0011,
            WAIT =  4'b0100,
            STOP =  4'b0110,
            NACK =  4'b0111,
            RECV =  4'b1000;

//state machine
always@(posedge clk)begin
    if(rst)
        state <= IDLE;
    else
        state <= next_state;
end

always@(posedge clk)begin
    case(state)
        IDLE: begin
            error_r <= 0;
            ack_r <= 0;
            counter <=0;
            index_counter <= 0;
            float_scl <=1;
            if(start) begin
                next_state <= START;
                float_sda <= 0; //start condition
            end
            else begin 
                next_state <= IDLE;
                float_sda <= 1;
            end
        end
        START:begin
            index_counter <= 31;    //we use this way to start in 0
            if(counter==t_start)begin
                float_scl <= 0;
                counter <=0;          
                next_state <= SEND;      
            end
            else begin
                counter <= counter+1;
                next_state <= START;
            end
        end
        SEND: begin
            //we start here with scl in low
            if(counter == CLK_CYCLES)begin
                float_scl <= 0; //check!!
                counter <= 0;
                if((index_counter==8||index_counter==17|| index_counter==26)) begin
                    next_state <= ACK;
                    float_sda <= 1; //we free the sda line
                end
                else begin
                    next_state <= SEND;
                end
            end
            else if(counter == CLK_CYCLES/2) begin
                counter <= counter +1;
                float_scl <= 1;
                next_state <= SEND;
            end
            else if(counter == CLK_CYCLES/4)begin
                //change the data in sda in the middle of the low semi cycle
                counter <= counter +1;
                next_state <= SEND;
                index_counter <= index_counter+1;  
            end
            else begin
                counter <= counter +1;
                next_state <= SEND;
                float_sda <= ctr_reg[index_counter];
            end
        end
        ACK: begin
            if(counter == CLK_CYCLES*3/4)begin
                //we are in the middle of the high semicycle
                counter <= counter +1;
                ack_r = sda_in;
            end
            else if(counter==CLK_CYCLES)begin
                counter <= 0;
                float_scl <= 0;
                if(ack_r)begin
                    if(index_counter==26)
                        next_state <= STOP;
                    else if((index_counter==17)&&ctr_reg[7])
                        next_state <= RECV;
                    else
                        next_state <= WAIT;
                end 
                else begin
                    next_state <= STOP;
                    error_r <= 1;
                end
            end
            else if(counter==CLK_CYCLES/2)begin
                float_scl <= 1;
                counter <= counter +1;
            end
            else begin
                counter <=counter + 1;
            end
        end
        WAIT: begin
            if(counter==t_wait) begin
                next_state <= SEND;
                counter <= 0;
            end
            else begin
                counter <= counter +1;
                next_state <= WAIT;
            end
        end
        STOP: begin
            if(counter==CLK_CYCLES/2)begin
                float_scl <= 1;
                counter <= counter+1;
                next_state <= STOP;
            end
            else if(counter==(CLK_CYCLES/2+t_stop))begin
                float_sda <= 1;
                next_state <= IDLE;
            end
            else begin
                counter <= counter +1;
                next_state <= STOP;
            end
        end
        RECV: begin
            //todo
            next_state <= IDLE;
        end
        NACK: begin
            //todo
            next_state <= IDLE;
        end
        default:
            next_state <= IDLE;
    endcase
end


endmodule
