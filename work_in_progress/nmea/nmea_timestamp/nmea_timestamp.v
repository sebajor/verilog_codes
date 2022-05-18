`default_nettype none
`include "includes.v"

/*
*   Author: Sebastian Jorquera
*   This module receives a NMEA to obtain a timestamp.
*   The fpga receives a NMEA stream and search for the $GPZDA command, then 
*   reads the time information and parse it. To have a synchronization in the
*   sub-second range it waits the PPS to change the second value.
*/


module nmea_timestamp #(
    parameter CLK_FREQ = 25_000_000,
    parameter BAUD_RATE = 115200,
    parameter DEBOUNCE_LEN = 5
) (
    input wire clk, 
    input wire rst,

    input wire i_uart_rx,
    input wire i_pps,

    output wire pattern_found,

    output wire [5:0] sec, min,
    output wire [4:0] hr,
    output wire [31:0] subsec,
    output wire bcd_valid,
    output wire pps
);

//pps debouncer
reg [DEBOUNCE_LEN-1:0] sync_pps=0;
reg pps_delay=0, pps_internal=0;
always@(posedge clk)begin
    sync_pps <= {sync_pps[DEBOUNCE_LEN-2:0], i_pps};
    pps_delay <= pps_internal;
    if(&sync_pps)
        pps_internal <= 1;
    else if(~(|sync_pps))
        pps_internal <= 0;
end

wire pps_rise = pps_internal & ~pps_delay;


//uart receiver
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
    .din_valid(uart_data_valid),
    .pattern_found(pattern_found),
    .info_data(info_data),
    .info_valid(info_valid)
);



wire [6:0] time_data;
wire time_valid;

ascii2bin #(
    .DIGITS(2)
) ascii2bin_inst (
    .clk(clk),
    .rst(rst | time_valid),
    .ascii_in(info_data),
    .din_valid(info_valid),
    .dout(time_data),
    .dout_valid(time_valid)
);

reg [5:0] sec_r=0, min_r=0;
reg [4:0] hr_r=0;
reg [31:0] subsec_r=0;
//subsecond counter
always@(posedge clk)begin
    if(pps_rise)
        subsec_r <= 0;
    else
        subsec_r <= subsec_r+1;
end


//0:hour, 1:minute, 2:second
reg [1:0] counter=0;
always@(posedge clk)begin
    if(rst)begin
        counter <=0;
    end
    else if((counter!=3) & time_valid)begin
        counter <= counter+1;
        case(counter)
            0:  hr_r <= time_data;
            1:  min_r <= time_data;
            2:  sec_r <= time_data;
        endcase
    end
    else if(counter == 3)begin
        if(pps_rise)begin
            if(sec_r == 59)begin
                sec_r <=0;
                if(min_r == 59)begin
                    min_r <=0;
                    if(hr_r==23)
                        hr_r <= 0;
                    else
                        hr_r <= hr_r+1;
                end
                else
                    min_r <= min_r+1;
            end
            else
                sec_r <= sec_r+1;
        end
    end
end

assign hr = hr_r;
assign min = min_r;
assign sec = sec_r;
assign subsec = subsec_r;
assign pps = pps_rise;
assign bcd_valid = (counter==3);



endmodule
