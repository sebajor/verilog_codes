`default_nettype none
/*
*   Author: Sebastian Jorquera
*   Module to convert a stream of number in ascii to its binary value
*   This module was made to parse the NMEA code, so it got several cycles between
*   two sucessive valid inputs.
*   The GPZDA commands has the following fields (and more)
*   $GPZDA,hhmmss,dd,MM, ..., chks
*   where h=hour, m=minutes, s=second, d=days, M=month
*
*/

module ascii2bin #(
    parameter DIGITS = 3
) (
    input wire clk,
    input wire rst,

    input wire [7:0] ascii_in,
    input wire din_valid,

    output wire [$clog2(10**(DIGITS))-1:0] dout,
    output wire dout_valid
);

//convert the digit into its value
reg din_valid_r=0;
reg [7:0] ascii_digit=0;
always@(posedge clk)begin
    din_valid_r <= din_valid;
    if(din_valid)begin
        case(ascii_in)
            48: ascii_digit <= 0;
            49: ascii_digit <= 1;
            50: ascii_digit <= 2;
            51: ascii_digit <= 3;
            52: ascii_digit <= 4;
            53: ascii_digit <= 5;
            54: ascii_digit <= 6;
            55: ascii_digit <= 7;
            56: ascii_digit <= 8;
            57: ascii_digit <= 9;
            default: ascii_digit <=0;
        endcase
    end
end


reg [$clog2(10**(DIGITS))-1:0] mult_vals [DIGITS-1:0];
integer i;
initial begin
    for(i=0; i<DIGITS; i=i+1)begin
        mult_vals[i] = 10**(i);
    end
end

//start generating the value
reg [31:0] counter=(DIGITS-1);
reg [$clog2(10**(DIGITS))-1:0] dout_r=0, temp=0;
reg din_valid_rr=0, dout_valid_r=0;


always@(posedge clk)begin
    din_valid_rr <= din_valid_r;
    temp <= mult_vals[counter]*ascii_digit;
end

always@(posedge clk)begin
    if(rst)begin
        counter <=(DIGITS-1);
        dout_r <=0;
        dout_valid_r <=0;
    end
    else if(din_valid_rr)begin 
        dout_r <= dout_r+temp;
        if(counter!=0)begin
            counter <= counter-1;
        end
        if(counter==(0))
            dout_valid_r <=1;
    end
    else
        dout_valid_r <=0;
end

assign dout_valid = dout_valid_r;
assign dout = dout_r;

endmodule
