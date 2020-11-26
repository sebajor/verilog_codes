module uart_rx #(
        parameter CLK_PER_BITS = 217,
        parameter N_BITS = 8
        ) (

            input clk,
            input rst,
            input rx_phy,
            output [N_BITS-1:0] rx_data,
            output rx_valid
          );
        reg [2:0] state;
        reg [2:0] next_state;
        reg r_valid;
        reg [N_BITS-1:0] r_data, out_data;
        reg [$clog2(CLK_PER_BITS):0] timer;
        reg [$clog2(N_BITS):0] index;

        
        localparam  state0 = 3'b000;
        localparam  state1 = 3'b001;
        localparam 	state2 = 3'b010;
        localparam  state3 = 3'b011;
        localparam  state4 = 3'b100;
        localparam  state5 = 3'b101;
        localparam	state6 = 3'b110;


        always@(posedge clk) begin
        if(rst) state <= state0;
        else    state <= next_state;      
        end    

    always@(*)begin
    case(state)
        state0:
            begin
                if(rx_phy)     next_state = state0;
                else            next_state = state1;
            end
        state1:
            begin
                if(timer == (CLK_PER_BITS-1)/2) begin
                    if(~rx_phy)    next_state = state2;
                    else            next_state = state0;
                end
                else        next_state = state1;
            end
        state2:
            next_state = state3;
        state3:
            begin
                if(timer == CLK_PER_BITS-1) next_state = state4;
                else                        next_state = state3;
            end    
        state4:
            begin
                if(index == N_BITS-1)       next_state = state6;
                else                        next_state = state5;
            end
        state5:
            next_state = state2;
        state6:
            next_state = state0;
        default:
            next_state = state0;

    endcase
end

    
always@(posedge clk)begin
    case(state) 
        state0:
            begin
                r_valid <= 0;
                timer <= 0;
                index <= 0;
                r_data <= 0;
            end
        state1:
            timer <= timer + 1;
        state2:
            begin
                timer <=0;
            end 
        state3:
            timer <= timer +1;
        state4:
            r_data[index] <= rx_phy;
        state5:
            index<=index+1;
        state6:
            r_valid <= 1;
    endcase
end

always@(posedge r_valid)begin
    out_data <= r_data; 
end

assign rx_data = out_data;
assign rx_valid = r_valid;
endmodule 

