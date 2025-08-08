`default_nettype none
`include "feedback_delay_line.v"
`include "../../../../xlx_templates/ram/simple_single_port/single_port_ram_read_first.v"
`include "../../../../dsp/delay/delay.v"


module feedback_delay_line_tb #(
    parameter DIN_WIDTH = 16,
    parameter FIFO_DEPTH= 32,
    parameter RAM_PERFORMANCE = "HIGH_PERFORMANCE"
) (
    input wire clk,
    input wire rst,
    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,

    output wire [DIN_WIDTH-1:0] dout,
    output wire dout_valid

);

feedback_delay_line #(
    .DIN_WIDTH(DIN_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH),
    .RAM_PERFORMANCE(RAM_PERFORMANCE)
)feedback_delay_line_inst (
    .clk(clk),
    .rst(rst),
    .din(din),
    .din_valid(din_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);

wire [DIN_WIDTH-1:0] delay_data;
delay #(
    .DATA_WIDTH(DIN_WIDTH),
    .DELAY_VALUE(FIFO_DEPTH+2)
) delay_inst (
    .clk(clk),
    .din(din),
    .dout(delay_data)
);

endmodule
