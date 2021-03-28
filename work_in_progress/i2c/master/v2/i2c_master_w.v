`default_nettype none

//TODO: put a error flag somewhere!

module i2c_master_w #(
    parameter CLK_FREQ = 25_000_000,
    parameter I2C_FREQ = 100_000
) (
    input wire clk,
    input wire rst,

    input wire [6:0] dev_addr,
    input wire [7:0] reg_addr,
    input wire [7:0] data,

    input wire send,
    output wire busy,

    output wire sda_out,
    input wire sda_in,
    output wire scl_out

);
/*  write a 8 bit register in a i2c device, in the top module with sda
    the output pin you should use: 
    
    assign sda = sda_out? 1'bZ: 1'b0;   
    assign sda_in = sda;
*/
localparam CLK_RED = CLK_FREQ/I2C_FREQ;
//states
localparam IDLE = 3'b001;
localparam START = 3'b010;
localparam DATA  = 3'b011;
localparam ACK = 3'b100;
localparam STOP = 3'b101;


reg sda_float = 1'b1;
reg scl_float = 1'b1;

assign sda_out = sda_float;
assign scl_out = scl_float;


reg [$clog2(CLK_RED)-1:0] counter=0;
reg [2:0] state=IDLE, next_state=IDLE;
/*
always@(posedge clk)begin
    if(rst)
        state <= IDLE;
    else
        state <= next_state;
end
*/
assign busy = ~(state==IDLE);


reg [4:0] index=0;    //counter to access to the words
reg [23:0] message=1;

//reverse msb to lsb
genvar i;
wire [7:0] data_msb, reg_addr_msb;
wire [6:0] dev_addr_msb;
for(i=0; i<7; i=i+1) begin
    assign data_msb[7-i] = data[i];
    assign reg_addr_msb[7-i] = reg_addr[i];
    assign dev_addr_msb[6-i] = dev_addr[i];
end
assign data_msb[0] = data[7];
assign reg_addr_msb[0] = reg_addr[7];
//create the message packet
always@(posedge clk)begin
    if(send && (state==IDLE))begin
        message = {data_msb, reg_addr_msb, 1'b0, dev_addr_msb}; //ut
    end
end

reg ack=0;
always@(posedge clk)begin
    if(rst)begin
        state <= IDLE;
    end
    else begin
        case(state)
            IDLE: begin
                ack <= 0;
                index <= 0;//{24{1'b1}};    //to start in the 0 when adding 1, check!
                counter <=0;
                sda_float <= 1'b1;
                scl_float <= 1'b1;
                if(send)
                    state <= START;
                else
                    state <= IDLE;
            end
            START: begin
                if(counter==0)begin
                    sda_float <= 1'b0;
                    state <= START;
                    counter <= counter+1;
                end
                else if(counter==CLK_RED/4)begin    //check timming if doesnt work
                    scl_float <= 1'b0;
                    state <= DATA;
                    counter<=0;
                end
                else begin
                    counter <= counter+1;
                    state <= START;
                end 
            end
            DATA: begin
                if(counter==CLK_RED/4)begin
                    //we are in the middle of the low scl
                        sda_float <= message[index];
                        counter <= counter+1;
                        index<= index+1;
                        state <= DATA;
                end
                else if(counter==CLK_RED/2)begin
                    //change scl low to high
                    scl_float <= 1'b1;
                    counter <= counter+1;
                    state <= DATA;
                end
                else if(counter==CLK_RED)begin
                    counter<=0;
                    scl_float <= 1'b0;
                    if((index==8) || (index==16) || (index==24)) //check!!! creo que es 8,16,24
                        state <= ACK;
                    else
                        state <= DATA;
                end
                else begin
                    state <= DATA;
                    counter <= counter +1;
                end
            end
            ACK:begin
                if(counter==CLK_RED/4)begin
                    //middle of low scl
                    counter<= counter+1;
                    sda_float <= 1; //free the line
                end
                else if(counter==CLK_RED/2)begin
                    counter <= counter+1;
                    scl_float <= 1'b1;
                end
                else if(counter==3*CLK_RED/4)begin
                    //middle of high scl
                    counter<= counter+1;
                    ack <= sda_in;           
                end
                else if(counter==CLK_RED)begin
                    scl_float <= 1'b0;
                    if(~ack)begin
                        counter <=0;
                        if(index==24)           //check!!
                            state <= STOP;
                        else begin
                            //index <= index+1;
                            state <= DATA;
                        end
                    end
                    else begin
                        state <= STOP;
                    end
                end
                else begin
                    counter <= counter+1;
                end
            end
            STOP: begin
                counter <= counter+1;
                if(counter==CLK_RED/4)begin
                    sda_float <= 1'b0;
                end 
                else if(counter==CLK_RED/2)
                    scl_float <= 1'b1;
                else if(counter==3*CLK_RED/4)begin
                    counter <= 0;
                    sda_float <= 1'b1;
                    state <= IDLE;
                end
            end
            default:    state <= IDLE;
        endcase
    end
end

endmodule
