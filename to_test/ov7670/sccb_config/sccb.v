/*
based on the code 
https://github.com/westonb/OV7670-Verilog
*/

`default_nettype none


module sccb #(
    parameter CLK_FREQ = 25_000_000,
    parameter SCCB_FREQ = 100000
) (
    input wire clk,
    input wire start,
    input wire [7:0] addr,
    input wire [7:0] data,
    output reg rdy,
    output reg SIOC_oe,
    output reg SIOD_oe
);
//the idea is using the oe outputs to enable or
//disable inouts in the top level 

localparam  CAM_ADDR = 8'h42;
localparam FSM_IDLE = 0;
localparam FSM_START = 1;
localparam FSM_LOAD = 2;
localparam FSM_TX_BYTE1 = 3;
localparam FSM_TX_BYTE2 = 4;
localparam FSM_TX_BYTE3 = 5;
localparam FSM_TX_BYTE4 = 6;
localparam FSM_END_SIG1 = 7;
localparam FSM_END_SIG2 = 8; 
localparam FSM_END_SIG3 = 9;
localparam FSM_END_SIG4 =10;
localparam FSM_DONE = 11;
localparam FSM_TIMER = 12;


//we have 4 bytes and done states to handle 
//data and clk transitions

initial begin
    SIOC_oe = 0;
    SIOD_oe = 0;
    rdy = 1;
end

reg [3:0] FSM_state=0, FSM_return_state =0;
reg [31:0] timer=0;
reg [7:0] save_data, save_addr;
reg [1:0] byte_counter=0;
reg [7:0] tx_byte =0;
reg [3:0] byte_index =0;

//in this implmentation the fsm just stall 9 cycles 
//waiting the ack from the slave, but its just that
//it doesnt need it to change the state


//SIOD and SIOC are inverted, ie when siod_oe = 0; siod is high

always@(posedge clk) begin
    case(FSM_state)
        FSM_IDLE: begin
            SIOD_oe <= 0;   
            SIOC_oe <= 0;
            byte_index <= 0;
            byte_counter <=0;
            if(start)begin
                FSM_state <= FSM_START;
                save_addr <= addr;
                save_data <= data;
                rdy <= 0;
            end
            else begin
                rdy <= 1;
            end
        end
        FSM_START: begin
            //start condition, take sdio low
            FSM_state <= FSM_TIMER;
            FSM_return_state <= FSM_LOAD;
            timer <= (CLK_FREQ/(4*SCCB_FREQ));
            SIOC_oe <= 0;
            SIOD_oe <= 1;
        end
        FSM_TIMER: begin
            //shared timer state..you have to set timer
            //in he previous state
            if(timer ==0)begin
                FSM_state <= FSM_return_state;
                timer <= 0;
            end
            else begin
                FSM_state <= FSM_TIMER;
                timer <= timer -1;
            end
        end
        FSM_LOAD: begin
            FSM_state <= (byte_counter==3) ? FSM_END_SIG1 : FSM_TX_BYTE1;
            byte_counter <= byte_counter +1;
            byte_index <= 0;
            case(byte_counter)
                0: tx_byte <= CAM_ADDR;
                1: tx_byte <= save_addr;
                2: tx_byte <= save_data;
                default: tx_byte <= save_data;
            endcase
        end
        FSM_TX_BYTE1: begin //set SIOC low
            FSM_state <= FSM_TIMER;
            FSM_return_state <= FSM_TX_BYTE2;
            timer <= (CLK_FREQ/(4*SCCB_FREQ));
            SIOC_oe <= 1; 
        end
        FSM_TX_BYTE2: begin // assign SIOD data
            FSM_state <= FSM_TIMER;
            FSM_return_state <= FSM_TX_BYTE3;
            timer <= (CLK_FREQ/(4*SCCB_FREQ));
            SIOD_oe <= (byte_index==8) ? 0: ~tx_byte[7];    //allow ack
        end
        FSM_TX_BYTE3: begin //set SIOC high
            FSM_state <= FSM_TIMER;
            FSM_return_state <= FSM_TX_BYTE4;
            timer <= (CLK_FREQ/(2*SCCB_FREQ));
            SIOC_oe <= 0;   //output enable
        end
        FSM_TX_BYTE4: begin //chek end of byte or end of msg
            FSM_state <= (byte_index==8) ? FSM_LOAD : FSM_TX_BYTE1;
            tx_byte <= tx_byte<<1;  //shift next data bit
            byte_index <= byte_index+1;
        end
        FSM_END_SIG1: begin //in this state SIOC = SIOD = high
                            //stop condition starts with SIOC low
            FSM_state <= FSM_TIMER;
            FSM_return_state <= FSM_END_SIG2;
            timer <= (CLK_FREQ/(4*SCCB_FREQ));
            SIOC_oe <= 1;
        end
        FSM_END_SIG2: begin //now we set SIOD to low
            FSM_state <= FSM_TIMER;
            FSM_return_state <= FSM_END_SIG3;
            timer <= (CLK_FREQ/(4*SCCB_FREQ));
            SIOD_oe <= 1;
        end
        FSM_END_SIG3: begin //SIOC to high
            FSM_state <= FSM_TIMER;
            FSM_return_state <= FSM_END_SIG4;
            timer <= (CLK_FREQ/(4*SCCB_FREQ));
            SIOC_oe <= 0;
        end
        FSM_END_SIG4: begin //SIOD to high
            FSM_state <= FSM_TIMER;
            FSM_return_state <= FSM_DONE;
            timer <= (CLK_FREQ/(4*SCCB_FREQ));
            SIOD_oe <= 0;
        end
        FSM_DONE: begin
            FSM_state <= FSM_TIMER;
            FSM_return_state <= FSM_IDLE;
            timer <= (2*CLK_FREQ/(SCCB_FREQ));
            byte_counter <= 0;
        end
        default: begin
            FSM_state <= FSM_IDLE;
        end
    endcase
end


endmodule 
