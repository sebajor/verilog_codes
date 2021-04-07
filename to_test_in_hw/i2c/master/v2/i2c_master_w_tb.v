`default_nettype none
`include "i2c_master_w.v"

module i2c_master_w_tb #(
    parameter CLK_FREQ = 100_000_000,
    parameter I2C_FREQ = 100_000_0
) (
    input wire clk,
    input wire rst,
    input wire [6:0] dev_addr,
    input wire [7:0] reg_addr,
    input wire [7:0] data,
    input wire send,
    output wire busy,
    output wire sda_out,
    input wire sda_in,
    output wire scl_out
);

i2c_master_w #(
    .CLK_FREQ(CLK_FREQ),
    .I2C_FREQ(I2C_FREQ)
) i2c_master_w_inst (
    .clk(clk),
    .rst(rst),
    .dev_addr(dev_addr),
    .reg_addr(reg_addr),
    .data(data),
    .send(send),
    .busy(busy),
    .sda_out(sda_out),
    .sda_in(sda_in),
    .scl_out(scl_out)
);

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end

endmodule
