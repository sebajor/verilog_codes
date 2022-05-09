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

    output wire [5:0] sec, min,
    output wire [4:0] hr,
    output wire [8:0] day,
    output wire [31:0] ms,
    output wire bcd_valid,
    output wire pps
);


uart_rx #(
    CLK_FREQ = 25_000_000,
    BAUD_RATE = 115200,
    N_BITS = 8
) uart_rx_inst (
    .rst(),
    .clk(),
    .rx_data(), 
    .uart_rx_tdata(),
    .uart_rx_tvalid(),
    .uart_rx_tready(1'b1)
);



endmodule
