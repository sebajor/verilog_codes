`default_nettype none
`include "irig_bcd.v"

module irig_bcd_tb (
    input wire clk,
    input wire rst,

    input wire calibrate,
    input wire cont, //if you want to be trying to calibrate always put this in 1
    input wire [31:0] one_count, zero_count, id_count,
    input wire [31:0] debounce,

    input wire din,
    
    //bcd data
    output wire [5:0] sec,
    output wire [5:0] min,
    output wire [4:0] hr,
    output wire [8:0] day,
    output wire bcd_valid,

    //output pps each second
    output wire pps
);

irig_bcd irig_bcd_inst (
    .clk(clk),
    .rst(rst),
    .calibrate(calibrate),
    .cont(cont),
    .one_count(one_count), 
    .zero_count(zero_count),
    .id_count(id_count),
    .debounce(debounce),
    .din(din),
    .sec(sec),
    .min(min),
    .hr(hr),
    .day(day),
    .bcd_valid(bcd_valid),
    .pps(pps)
);


endmodule
