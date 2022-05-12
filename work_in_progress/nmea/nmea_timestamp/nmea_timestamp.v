`default_nettype none

/*
*   Author: Sebastian Jorquera
*   This module receives a NMEA to obtain a timestamp.
*   The fpga receives a NMEA stream and search for the $GPZDA command, then 
*   reads the time information and parse it. To have a synchronization in the
*   sub-second range it waits the PPS to change the second value.
*/


module nmea_timestamp #(
    parameter CLK_FREQ = 25_000_000,
    parameter BAUD_RATE = 9600
) (
    input wire clk, 
    input wire rst,

    input wire i_uart_rx,
    input wire i_pps,

    output wire pattern_found,

    output wire [5:0] sec, min,
    output wire [4:0] hr,
    output wire [8:0] day,
    output wire [31:0] ms,
    output wire bcd_valid,
    output wire pps
);

wire [7:0] uart_data;
wire uart_data_valid;

uart_rx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE),
    .N_BITS(8)
) uart_rx_inst (
    .rst(rst),
    .clk(clk),
    .rx_data(i_uart_rx), 
    .uart_rx_tdata(uart_data),
    .uart_rx_tvalid(uart_data_valid),
    .uart_rx_tready(1'b1)
);


wire [7:0] info_data;
wire info_valid;

pattern_search #(
    .PATTERN_LEN(6),
    .PATTERN("GPZDA,"),
    .INFO_LEN(6)//14
) pattern_search_inst (
    .clk(clk),
    .rst(rst),
    .din(uart_data),
    .din_valid(aurt_data_valid),
    .pattern_found(pattern_found),
    .info_data(info_data),
    .info_valid(info_valid)
);






endmodule
