`default_nettype none
`include "vector_accumulator.v"
`include "rtl/sync_simple_dual_ram.v"

module vector_accumulator_tb #(
    parameter DIN_WIDTH = 16,
    parameter VECTOR_LEN = 64,
    parameter DOUT_WIDTH = 32,
    parameter DATA_TYPE = "signed"  //signed or unsigned 
) (
    input wire clk,
    input wire new_acc,     //new accumulation, set it previous the first sample of the frame
    
    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,

    output wire [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);

vector_accumulator #(
    .DIN_WIDTH(DIN_WIDTH),
    .VECTOR_LEN(VECTOR_LEN),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DATA_TYPE(DATA_TYPE)
)vector_accumulator_inst  (
    .clk(clk),
    .new_acc(new_acc),
    .din(din),
    .din_valid(din_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);

endmodule
