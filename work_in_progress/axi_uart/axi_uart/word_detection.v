`default_nettype none


module word_detection #(
    parameter UART_BIT = 8,
    parameter PATTERN_SIZE = 3,
    parameter PATTERN = "mrd",
    parameter INFO_SIZE = 8 //bytes    
) (
    input wire clk,
    input wire [UART_BIT-1:0] uart_in,
    input wire uart_valid,

    output wire [INFO_SIZE*UART_BIT-1:0] dout_tdata,
    output wire dout_tvalid,
    input wire dout_tready
);


reg [8*(PATTERN_SIZE+INFO_SIZE)-1:0] shift_word=0, dout_r=0;
reg dout_valid_r;
assign dout_tdata = dout_r;
assign dout_tvalid = dout_valid_r;

always@(posedge clk)begin
    if(uart_valid)
        shift_word <= {shift_word[8*(PATTERN_SIZE+INFO_SIZE-1)-1:0],uart_in};
end
    
always@(posedge clk)begin
    if(shift_word[PATTERN_SIZE+INFO_SIZE-1-:PATTERN_SIZE]==PATTERN)begin
        dout_r <= shift_word;
        dout_valid_r <= 1;
    end
    else if(dout_tready)begin
        dout_valid_r <= 0;
    end
end


endmodule
