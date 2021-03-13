module uart_tx #( 
    parameter TICKS = 217   //clk divider factor
)(
    input [7:0] axis_tdata,
    input axis_tvalid,
    output axis_tready, 
 
    input clk,
    output tx_data
);

    localparam idle = 3'b000;
    localparam start =3'b001; 
    localparam transmitting = 3'b010;
    localparam finish = 3'b011;


    reg [8:0] r_data = 1;
    reg tready = 0;
    reg [2:0] state=idle; 
    reg [2:0] next_state;
    reg [3:0] index=0;
    reg [$clog2(TICKS)+1:0] counter=0; 
    reg out_data;

    always@(posedge clk) begin
       state <= next_state;
       case(state)
        idle:
            begin
                tready <= 1;
                counter <=0;
                index <= 0;
                out_data <=1;
                if(axis_tvalid)     r_data <= {1'b1,axis_tdata};
            end
        start:
            begin 
                tready <=0;
                out_data <= 0;
                if(counter == TICKS)    counter <=0;
                else                    counter = counter+1;
            end
        transmitting:
           begin
                out_data <= r_data[index];
                if(counter == TICKS)begin
                    counter <=0;
                    index <= index +1;
                end
                else    counter = counter +1;
            end
        finish:
            begin
                out_data <= 1;
                counter <= counter+1;
            end
       endcase 
    end

    always@(*) begin
        case(state)
            idle:
                if(axis_tvalid) next_state = start;
                else            next_state = idle;
            start:
                if(counter==TICKS)  next_state = transmitting;
                else                next_state = start;
            transmitting:
                if(index==8)        next_state = finish;
                else                next_state = transmitting;
            finish:
                if(counter==TICKS)  next_state = idle;
                else                next_state = finish;
        endcase
    end


assign axis_tready = tready;
assign tx_data = out_data; 


endmodule
