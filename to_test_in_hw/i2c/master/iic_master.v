`default_nettype none

//Single master of an i2c line
//in this implementation the lines are pull up by external source.
//its easilly change but look it!

//this code was made looking to the SCCB interface
module iic_master #(
    parameter FPGA_CLK = 25_000_000,
    parameter IIC_CLK = 10_000,
) (
    input wire clk,
    input wire rst,
    //control signals
    input wire start,   //start communication
    input wire [31:0] ctr,
    output wire [7:0] i2c_recv,
    output wire i2c_recv_valid,
    output wire error,
    //iic signals
    inout wire SCL,
    inout wire SDA
);
/*like i am going to test it in a spartan 6 i have to define
the clog2 function >:(
*/
function integer clogb2;
    input [31:0] val;
    begin
        val = val-1;
        for(clogb2=0; val>0; clogb2=clogb2+1)
            val = val>>1;
    end
endfunction

localparam CLK_CYCLES = FPGA_CLK/IIC_CLK;
localparam t_hda = 5*FPGA_CLK/1_000_000; //4us is the minimum in start condition
localparam t_wait = CLK_CYCLES/4;        //wait t_wait after an ack to start the next transaction

//for this pin assignation the line is pull up by an outside logic
//TAKE THAT INTO ACOUNT!!!
reg float_sda=1, float_scl=1;   //those are sda and scl whn we are sourcing them
wire sda_in, scl_in; //sda and scl when we are listen to them

assign scl_in = SCL;
assign SCL = float_scl ? 1'bZ:1'b0;
assign sda_in = SDA;
assign SDA = float_sda ? 1'bZ:1'b0;


reg [clogb2(CLK_CYCLES)-1:0] counter=0; //counter for clock divider 
reg [5:0] index_counter =0; //index counter
reg [31:0] ctr_reg=0; 
/*
0-6: 7 bit slave address (msb is send first)
7: 0=write, 1=read
8-15: internal address of the slave, if is necessary
16-24: data to write

25: 0=internal address necessary 1:not necesarry just send the data
26: in case of nack of the slave 0:stop 1:repeated start
*/
always@(posedge clk)begin
    //the order is inverted for the address and the data
    ctr_reg[6:0] <= ctr[0:6];
    ctr_reg[7] <= ctr[7];
    ctr_reg[15:8]<= ctr[8:15];
    ctr_reg[24:16] <= ctr[16:24];
    ctr_reg[31:25] <= ctr[31:25];
end

reg [7:0] recv=0;
reg error_r=0;
reg [3:0] state=0, next_state=0;

//states
localparam  IDLE = 4'b0000,
            START = 4'b0001,
            FIRST = 4'b0010,
            ACK = 4'b0011,
            SECOND = 4'b0100,
            THIRD = 4'b0101,
            STOP = 4'b0111,
            NACK = 4'b1000,
            RECV = 4'b1001,
            PRE_START = 4'b1010;

//state machine, note: handle a proper termination when reseting
reg ack_r=0;
always@(posedge clk)begin
    if(rst)
        state <= IDLE;
    else 
        state <= next_state;
end

always@(posedge clk)begin
    case(state)begin
        IDLE:begin
            ack_r <=0;
            counter <= 0;
            float_scl <=1;
            float_sda <=1;
            if(start)   
                next_state <= PRE_START;
            else
                next_state <= IDLE;
        end
        PRE_START:begin
            //start condition.. pull sda low and wait until thda
            float_sda <=0;
            index_counter <= 0;
            error_r <= 0;
            if(counter==t_hda)begin
                next_state <= START;
                counter <= 0;
            end
            else begin
                next_state <= PRE_START;
                counter <= counter +1;
            end
        end
        START: begin
            //count half of the i2c period and present the first value
            if(counter == CLK_CYCLES/2)begin
                next_state <= FIRST;
                counter <= 0;
            end
            else begin
                next_state <= START;
                counter <= counter+1;
            end
        end
        FIRST: begin
            //when start sda=0 and scl=1
            //send the first word+read/write option
            ack_r <=0;
            if((index_counter==8)&&counter==CLK_CYCLES/2)begin       
                //check!! we should arrive here in the low cycle of the scl 
                float_sda <= 0;
                next_state <= ACK;
                counter <= 0; 
                float_scl <= 1;
            end
            else if(counter==CLK_CYCLES/4)begin
                index_counter <= index_counter+1;
                counter <= counter +1;
                next_state <= FIRST;
            end
            else if(counter==CLK_CYCLES/2)begin
                float_scl <= ~float_scl;
                counter <= 0;
                next_state <= FIRST;
            end
            else begin
                counter <= counter+1;
                next_state <=FIRST;
                if(index_conter!=8)
                    float_sda <= ctr_reg[index_counter]; 
                else 
                    float_sda <=1;
            end
        end
        ACK: begin
            //wait for an ack signal, if comes from the 1st word
            //goes to the second one, if the previous state was the 
            //2nd view if its a read cmd or if a 3rd word is need
            //if there is not an ack goes to the stop condition
            float_sda <= 0;
            if(counter==CLK_CYCLES/4)begin
                //error.. stop condition!
                //next_state <= STOP;
                counter <= counter+1;
                if(sda_in)
                    ack_r <= 1;
                else
                    error_r <= 1;
            end    
            else if(counter==CLK_CYCLES/2)begin
                counter <= counter +1;
                float_scl <= 0;
            end
            else if(counter==CLK_CYCLES)begin
                counter <= 0;
                if(ack_r && (index_counter==8))begin
                    next_state <= SECOND;
                    float_sda <= ctr_reg[8];
                end
                else if(ack_r && !ctr_reg[7] && index_counter==16)begin
                    next_state <= THIRD;
                    float_sda <= ctr_reg[16];
                end
                else if(ack_r && ctr_reg[7])begin
                    next_state <= RECV;
                    float_sda <= 1;
                end
                else if(ack_r && ctr_reg[25])
                    next_state <= STOP;
                else
                    next_state <= STOP;
            end
            else begin
                counter <= counter +1;
                next_state <= ACK;
            end  
        end
        SECOND: begin
            if(ack_r==1)begin
                float_scl <= 0;
                if(counter==t_wait)begin
                    ack_r <= 0;
                    counter <= 0;
                end
                else
                    counter <= counter+1;
            end
            else begin
                 if((index_counter==16)&&counter==CLK_CYCKLES/2)begin       
                    //check!! we should arrive here in the low cycle of the scl 
                    float_sda <= 0;
                    next_state <= ACK;
                    counter <= 0; 
                    float_scl <= 1;
                end
                else if(counter==CLK_CYCLES/4)begin
                    index_counter <= index_counter+1;
                    counter <= counter +1;
                    next_state <= FIRST;
                end
                else if(counter==CLK_CYCLES/2)begin
                    float_scl <= ~float_scl;
                    counter <= 0;
                    next_state <= SECOND;
                end
                else begin
                    counter <= counter+1;
                    next_state <=SECOND;
                    if(index_conter!=16)
                        float_sda <= ctr_reg[index_counter]; 
                    else 
                        float_sda <=1;
                end
            end 
        end
            
        THIRD: begin
            if(ack_r==1)begin
                float_scl <= 0;
                if(counter==t_wait)begin
                    ack_r <= 0;
                    counter <= 0;
                end
                else
                    counter <= counter+1;
            end
            else begin
                 if((index_counter==16)&&counter==CLK_CYCKLES/2)begin       
                    //check!! we should arrive here in the low cycle of the scl 
                    float_sda <= 0;
                    next_state <= ACK;
                    counter <= 0; 
                    float_scl <= 1;
                end
                else if(counter==CLK_CYCLES/4)begin
                    index_counter <= index_counter+1;
                    counter <= counter +1;
                    next_state <= FIRST;
                end
                else if(counter==CLK_CYCLES/2)begin
                    float_scl <= ~float_scl;
                    counter <= 0;
                    next_state <= SECOND;
                end
                else begin
                    counter <= counter+1;
                    next_state <=SECOND;
                    if(index_conter!=16)
                        float_sda <= ctr_reg[index_counter]; 
                    else 
                        float_sda <=1;
                end
            end
        end
        RECV: begin

        end        

        NACK:begin
            //when rading there is a nack to indicate that the reading process is ready 

        end

        STOP: begin
            if(ack_r==1)begin
                float_scl <= 0;
                if(counter==t_wait)begin
                    ack_r <= 0;
                    counter <= 0;
                end
                else 
                    counter <= counter+1;
            end
            else begin
                if(counter ==CLK_CYCLES/2) begin
                    float_sda <= 
                end

            end
        end            

        default: begin
            next_state <= IDLE;
        end

    endcase
end


endmodule
