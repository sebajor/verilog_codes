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
    parameter FILENAME = "sine.b"
) (
    input wire clk, 
    input wire en,

    output wire signed [DATA_WIDTH-1:0] dout
);




endmodule

