`default_nettype none

/*galois lfsr as a fancy counter

*/

lfsr_galois #(
    parameter DIN_WIDTH = 8,
    parameter LFSR_WIDHT = 4,
    parameter LFSR_INIT = 8'b01;

) (
    input wire clk,
    input wire rst,
    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,
    output wire dout,
    output wire dout_valid
);

endmodule
