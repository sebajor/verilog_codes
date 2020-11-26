`default_nettype none

module uart_tx #(
    parameter CLK_FREQ = 25_000_000,
    parameter BAUD_RATE = 115200
) (
    input [7:0] axis_tdata,
    input axis_tvalid,
    output axis_tready,

    input clk,
    output tx_data
);
    localparam N_TICKS = CLK_FREQ/BAUD_RATE;
    
    //states names
    localparam idle=2'b00;
    localparam start=2'b01;
    localparam transmitting=2'b10;
    localparam finish=2'b11;

    reg [8:0] r_data = 1;
    reg tready;
    reg [3:0] index=0;
    reg [1:0] state = idle;
    reg [1:0] next_state = idle;
    reg [$clog2(N_TICKS)-1:0] counter = 0;
    reg out_data=0;

    always@(posedge clk)begin
        state <= next_state;
        case(state)
            idle: begin
                tready <= 1;
                counter <= 0;
                index <= 0;
                out_data<= 1;
                if(axis_tvalid) r_data <= {1'b1, axis_tdata};
            end
            start:begin
                tready <= 0;
                out_data <=0;
                if(counter==N_TICKS)    counter <= 0;
                else    counter <= counter +1;
            end
            transmitting: begin
                out_data <= r_data[index];
                if(counter==N_TICKS)begin
                    counter <= 0;
                    index <= index+1;
                end
                else    counter <= counter +1;
            end
            finish: begin
                out_data <=1;
                counter <= counter +1;
            end
        endcase
    end
    
    always@(*)begin
        case(state)
            idle: begin
                if(axis_tvalid) next_state = start;
                else    next_state = idle;
            end
            start:begin
                if(counter==N_TICKS)    next_state = transmitting;
                else            next_state = start;
            end
            transmitting: begin
                if(index==8)    next_state = finish;
                else            next_state = transmitting;
            end
            finish: begin
                if(counter==N_TICKS)    next_state = idle;
                else                    next_state = finish;
            end
            default:
                next_state <= idle;
        endcase
    end

    assign axis_tready = tready;
    assign tx_data = out_data;
endmodule
