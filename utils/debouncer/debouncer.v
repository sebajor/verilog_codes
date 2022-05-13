`default_nettype none
/*
*   Author:Sebastian Jorquera
*   A simple debouncer
*
*/

module debouncer #(
    parameter DEBOUNCE_CYCLES = 5
) (
    input wire clk,
    input wire din,
    output wire dout
);
reg [DEBOUNCE_CYCLES-1:0] temp_value=0;
reg dout_r=0;
always@(posedge clk)begin
    temp_value <= {temp_value[DEBOUNCE_CYCLES-2:0], din};
    if(&temp_value)
        dout_r<=1;
    else if(~ (|temp_value)
        dout_r <=0 
end

assign dout = dout_r;

endmodule
