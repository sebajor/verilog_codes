`default_nettype none

module uart_rx #(
    parameter CLK_FREQ = 25_000_000,
    parameter BAUD_RATE = 115200,
    parameter N_BITS = 8
) (

    input rst,
    input wire clk,
    input rx_data,  //from the outside world
    output [N_BITS-1:0] uart_rx_tdata,
    output uart_rx_tvalid,
    input uart_rx_tready
);
    localparam  state0 = 3'b000;    //idle
    localparam  state1 = 3'b001;
    localparam  state2 = 3'b010;
    localparam  state3 = 3'b011;
    localparam  state4 = 3'b100;
    localparam  state5 = 3'b101;
    localparam  state6 = 3'b110;
    
    localparam N_TICKS = CLK_FREQ/BAUD_RATE;

    reg [2:0] state=0, next_state=0;
    reg r_valid=0, rr_valid;
    reg [N_BITS-1:0] r_data=0, rr_data=0;
    
    reg [$clog2(N_TICKS)-1:0] counter=0;
    reg [$clog2(N_BITS)-1:0] index = 0;


    always@(posedge clk)begin
        if(rst)
            state <= state0;
        else
            state <= next_state;
    end

    always@(*)begin
        case(state)
            state0: begin
                if(rx_data)     next_state = state0;
                else            next_state = state1;
            end
            state1: begin
                if(counter==(N_TICKS-1)/2) begin
                    if(~rx_data)    next_state = state2;
                    else            next_state = state0;
                end
                else
                    next_state = state1;
            end
            state2:
                next_state = state3;
            state3: begin
                if(counter == N_TICKS)  next_state = state4;
                else                    next_state = state3;
            end
            state4: begin
                if(index==(N_BITS-1)) next_state = state6;
                else                next_state = state5;
            end
            state5:
                next_state = state2;
            state6:
                next_state = state1; //state0;
            default:
                next_state = state0;
        endcase
    end

    always@(posedge clk)begin
        case(state) 
            state0: begin
                counter <= 0;
                r_valid <= 0;
                index <=0;
                r_data <=0;                
            end
            state1:begin
                counter <= counter +1;
                r_valid <=0;
            end
            state2:
                counter <=0;
            state3:
                counter <= counter +1;
            state4:
                r_data[index] <= rx_data;
            state5:
                index <= index+1;
            state6:begin
                r_valid <= 1;
                index <=0;
                counter <= 0;
            end
        endcase
    end

    always@(posedge clk)begin
        if(r_valid) begin
            rr_data<= r_data;
            rr_valid <= 1;
        end
        else begin
            rr_data <= rr_data;
            if(uart_rx_tready)
                rr_valid <= 0;
            else
                rr_valid <= rr_valid;
        end
    end

    assign uart_rx_tdata = rr_data;
    assign uart_rx_tvalid = rr_valid;

endmodule 





