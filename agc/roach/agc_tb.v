`default_nettype none
`include "agc.v"


module agc_tb #(
    parameter DIN_WIDTH = 8,
    parameter DIN_POINT = 7,
    parameter PARALLEL = 8,
    parameter DELAY_LINE = 32,
    parameter AVG_POW_APROX = "nearest",
    parameter UPDATE_CYCLES = 32,
    parameter COEF_WIDTH = 16,
    parameter COEF_POINT = 8,
    parameter GAIN_WIDTH = 16,
    parameter GAIN_POINT = 8,
    parameter GAIN_HIGH = 2048, //in sd is 8
    parameter GAIN_LOW = 0
) (
    input wire clk,
    input wire rst,

    input wire [DIN_WIDTH*PARALLEL-1:0] din,
    input wire din_valid,
    
    input wire [2*DIN_WIDTH-1:0] ref_pow,
    input wire [COEF_WIDTH-1:0] error_coef,
    
    output wire signed [GAIN_WIDTH-1:0] gain_out,
    output wire gain_out_valid,

    output wire signed [PARALLEL*(DIN_WIDTH+GAIN_WIDTH)-1:0] dout,
    output wire dout_valid
);

agc #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .PARALLEL(PARALLEL),
    .DELAY_LINE(DELAY_LINE),
    .AVG_POW_APROX(AVG_POW_APROX),
    .UPDATE_CYCLES(UPDATE_CYCLES),
    .COEF_WIDTH(COEF_WIDTH),
    .COEF_POINT(COEF_POINT),
    .GAIN_WIDTH(GAIN_WIDTH),
    .GAIN_POINT(GAIN_POINT),
    .GAIN_HIGH(GAIN_HIGH),
    .GAIN_LOW(GAIN_LOW)
) agc_inst (
    .clk(clk),
    .rst(rst),
    .din(din),
    .din_valid(din_valid),
    .ref_pow(ref_pow),
    .error_coef(error_coef),
    .gain_out(gain_out),
    .gain_out_valid(gain_out_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);

//to help the debug in the wavescope
localparam DOUT_WIDTH = DIN_WIDTH+GAIN_WIDTH;
wire [DIN_WIDTH+GAIN_WIDTH-1:0] dout0, dout1, dout2, dout3, 
                                dout4,dout5, dout6, dout7;

assign dout0 = dout[0+:DOUT_WIDTH];
assign dout1 = dout[DOUT_WIDTH+:DOUT_WIDTH];
assign dout2 = dout[2*DOUT_WIDTH+:DOUT_WIDTH];
assign dout3 = dout[3*DOUT_WIDTH+:DOUT_WIDTH];
assign dout4 = dout[4*DOUT_WIDTH+:DOUT_WIDTH];
assign dout5 = dout[5*DOUT_WIDTH+:DOUT_WIDTH];
assign dout6 = dout[6*DOUT_WIDTH+:DOUT_WIDTH];
assign dout7 = dout[7*DOUT_WIDTH+:DOUT_WIDTH];

wire [DIN_WIDTH-1:0] din0,din1,din2,din3,din4,din5,din6,din7;
assign din0 = din[0+:DIN_WIDTH];
assign din1 = din[DIN_WIDTH+:DIN_WIDTH];
assign din2 = din[2*DIN_WIDTH+:DIN_WIDTH];
assign din3 = din[3*DIN_WIDTH+:DIN_WIDTH];
assign din4 = din[4*DIN_WIDTH+:DIN_WIDTH];
assign din5 = din[5*DIN_WIDTH+:DIN_WIDTH];
assign din6 = din[6*DIN_WIDTH+:DIN_WIDTH];
assign din7 = din[7*DIN_WIDTH+:DIN_WIDTH];


initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end


endmodule
