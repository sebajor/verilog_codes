`default_nettype none
`include "fft_chann_flag.v"

module fft_chann_flag_tb #(
    parameter STREAMS = 8,
    parameter FFT_SIZE = 128,
    parameter DIN_WIDTH = 32
) (
    input wire clk,
    input wire sync_in,
    input wire [STREAMS*DIN_WIDTH-1:0] din,
    output wire sync_out,
    output wire [STREAMS*DIN_WIDTH-1:0] dout,

    //config
    input wire [31:0] config_flag,
    input wire [31:0] config_num,
    input wire config_en
);

fft_chann_flag #(
    .STREAMS(STREAMS),
    .FFT_SIZE(FFT_SIZE),
    .DIN_WIDTH(DIN_WIDTH)
)chann_flag_inst (
    .clk(clk),
    .sync_in(sync_in),
    .din(din),
    .sync_out(sync_out),
    .dout(dout),
    .config_flag(config_flag),
    .config_num(config_num),
    .config_en(config_en)
);

wire [DIN_WIDTH-1:0] ch0,ch1,ch2,ch3,ch4,ch5,ch6,ch7;
assign ch0 = dout[0+:DIN_WIDTH];
assign ch1 = dout[DIN_WIDTH+:DIN_WIDTH];
assign ch2 = dout[2*DIN_WIDTH+:DIN_WIDTH];
assign ch3 = dout[3*DIN_WIDTH+:DIN_WIDTH];
assign ch4 = dout[4*DIN_WIDTH+:DIN_WIDTH];
assign ch5 = dout[5*DIN_WIDTH+:DIN_WIDTH];
assign ch6 = dout[6*DIN_WIDTH+:DIN_WIDTH];
assign ch7 = dout[7*DIN_WIDTH+:DIN_WIDTH];


initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end

endmodule
