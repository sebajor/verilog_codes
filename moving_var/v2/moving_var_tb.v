`default_nettype none
`include "moving_var.v"

module moving_var_tb #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 15,
    parameter WINDOW_LEN = 16,
    parameter APPROX = "nearest"
)(
    input wire clk,
    input wire rst,
    input wire signed [DIN_WIDTH-1:0] din,
    input wire din_valid,
    
    output wire signed [DIN_WIDTH-1:0] moving_avg,
    output wire signed [2*DIN_WIDTH:0] moving_var,
    output wire dout_valid
);


moving_var #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .WINDOW_LEN(WINDOW_LEN),
    .APROX(APPROX)
) m_var_tb (
    .clk(clk),
    .rst(rst),
    .din(din),
    .din_valid(din_valid),
    
    .moving_avg(moving_avg),
    .moving_var(moving_var),
    .dout_valid(dout_valid)
);

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end


endmodule
