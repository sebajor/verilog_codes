`default_nettype none

/*
*   Author:Sebastian Jorquera
*   Quarter wave look up table (kind of). There is an boundary problem when
*   changing the polarity of the sine, so we need an extra value to keep it.
*/

module quarter_sine_lut #(
    parameter DATA_WIDTH = 16,
    parameter DATA_POINT = 14,
    parameter N = 1024,
    parameter FILENAME = "sine.b",
    parameter LEFT_SAMPLE = 16'd10;
) (
    input wire clk, 
    input wire en,

    output wire signed [DATA_WIDTH-1:0] dout
);


reg [DATA_WIDTH-1:0] mem [N/4-1];
initial begin
    $readmemb(FILENAME, mem)
end

reg [DATA_WIDTH-1:0] left_sample=LEFT_SAMPLE;

reg [$clog2(N/4)-1:0] addr_counter=0;
reg [2:0] state =0, next_state=0;

localparam QUARTER0=0,
           QUARTER1=1,
           QUARTER2=2,
           QUARTER3=3,
           LEFTOUT_SAMPLE0 = 5,
           LEFTOUT_SAMPLE1 = 6;
          


always@(posedge clk)begin
    if(rst)
        state <= 0;
    else
        state <= next_state;
end

always@(*)begin
    case(state)
        QUARTER0:begin
            if(&addr_counter)
                next_state = LEFTOUT_SAMPLE0;
            else
                next_state = QUARTER0;
        end
        LEFTOUT_SAMPLE0:
            next_state = QUARTER1;
        QUARTER1:begin
            if(addr_counter==0) //not sure..
                next_state = QUARTER2;
            else
                next_state = QUARTER1;
        end
        QUARTER2:begin
            if(&addr_counter)
                next_state = LEFTOUT_SAMPLE1;
            else
                next_state = QUARTER0;
        end
        LEFTOUT_SAMPLE1:
            next_state = QUARTER3;
        QUARTER3:begin
            if(addr_counter==0) //not sure..
                next_state = QUARTER2;
            else
                next_state = QUARTER1;
        end
    endcase
end

always@(posedge clk)begin
    case(state)
        QUARTER0:
            addr_counter <= addr_counter+1;
        QUARTER1:
            addr_counter <= addr_counter-1;
        QUARTER2:
            addr_counter <= addr_counter+1;
        QUARTER3:
            addr_counter <= addr_counter-1;
    endcase
end




endmodule

