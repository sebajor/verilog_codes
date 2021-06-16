`default_nettype none
`ifndef _ACT_
    `define _ACT_
    `include "/home/seba/Workspace/verilog_codes/dev/nn/neuron_v3/activation/relu/relu.v"
    `include "/home/seba/Workspace/verilog_codes/dev/nn/neuron_v3/activation/sigmoid/sigmoid.v"
`endif

module activation_function #(
    parameter DIN_WIDTH = 16,
    parameter DIN_INT = 2,
    parameter DOUT_WIDTH = 8,
    parameter DOUT_INT = 4,
    parameter ACTIVATION_TYPE = "relu",
    parameter FILENAME = "/home/seba/Workspace/verilog_codes/dev/nn/neuron_v3/activation/sigmoid_hex.mem"
) (
    input wire clk,
    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,
    output wire [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);

generate 
if(ACTIVATION_TYPE == "sigmoid")begin
    sigmoid #(
        .DOUT_WIDTH(DOUT_WIDTH),
        .DUOT_INT(DUOT_INT),
        .DIN_WIDTH(DIN_WIDTH),
        .DIN_INT(DIN_INT),
        .FILENAME(FILENAME)
    ) sigmoid_inst (
        .clk(clk),
        .din(din),
        .din_valid(din_valid),
        .dout(dout),
        .dout_valid(dout_valid)
    );
end
else if(ACTIVATION_TYPE=="relu")begin
relu #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_INT(DIN_INT),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_INT(DOUT_INT)
) relu_inst (
    .clk(clk),
    .din(din),
    .din_valid(din_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);

end


endgenerate



endmodule
