`default_nettype none
/*
LSFR Galois with bit-reverse
The polynomial of ethernet x^32+x^26+x^23+x^22+x^16+x^12+x^11+
                            x^10+x^8+x^7+x^5+x^4+x^2+x+1
*/
module crc32 #(
    parameter LFSR_WIDTH = 31,
    parameter LFSR_POLY = 31'h10000001,
    parameter LFSR_FEED_FORWARD = 0,
    parameter DATA_WIDTH = 8
) (
    input wire [DATA_WIDTH-1:0] din,
    input wire [LFSR_WIDTH-1:0] state_in,
    output wire [DATA_WIDTH-1:0] dout,
    output wire [LFSR_WIDTH-1:0] state_out
);



endmodule
