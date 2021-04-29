`default_nettype none
//`include "rom.v"

module sqrt_lut #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 10,
    parameter DOUT_WIDTH = 16,
    parameter DOUT_POINT = 12,
    parameter SQRT_FILE = "sqrt.hex"
) (
    input wire clk,
    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,

    output wire [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);


rom #(
    .N_ADDR(2**DIN_WIDTH),
    .DATA_WIDTH(DOUT_WIDTH),
    .INIT_VALS(SQRT_FILE)
) rom_sqrt (
    .clk(clk),
    .ren(din_valid),
    .radd(din),
    .wout(dout)
);

reg dout_valid_r=0;
always@(posedge clk)begin
    dout_valid_r <= din_valid;
end
assign dout_valid = dout_valid_r;



endmodule
