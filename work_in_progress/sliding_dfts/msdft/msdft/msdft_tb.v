`default_nettype none
`include "msdft.v"

module msdft_tb #(
    parameter DIN_WIDTH = 8,
    parameter DIN_POINT = 7,
    parameter TWIDD_WIDTH = 16,
    parameter TWIDD_POINT = 14,
    parameter TWIDD_FILE = "twidd_init.hex",
    parameter DFT_LEN = 128,
    parameter DOUT_WIDTH = 32,
    parameter DOUT_POINT = 21
) (
    input wire clk, 
    input wire rst,

    input wire signed [DIN_WIDTH-1:0] din_re, din_im,
    input wire din_valid,

    output wire signed [DOUT_WIDTH-1:0] dout_re, dout_im,
    output wire dout_valid,

    //configuration signals
    input wire axi_clock,
    input wire [2*TWIDD_WIDTH-1:0] bram_dat,
    input wire [$clog2(DFT_LEN)-1:0] bram_addr,
    input wire bram_we,
    output wire [2*TWIDD_WIDTH-1:0] bram_dout,

    input wire [31:0] delay_line
);


msdft #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .TWIDD_WIDTH(TWIDD_WIDTH),
    .TWIDD_POINT(TWIDD_POINT),
    .TWIDD_FILE(TWIDD_FILE),
    .DFT_LEN(DFT_LEN),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT)
) msdft_inst (
    .clk(clk), 
    .rst(rst),
    .din_re(din_re), 
    .din_im(din_im),
    .din_valid(din_valid),
    .dout_re(dout_re),
    .dout_im(dout_im),
    .dout_valid(dout_valid),
    .axi_clock(axi_clock),
    .bram_dat(bram_dat),
    .bram_addr(bram_addr),
    .bram_we(bram_we),
    .bram_dout(bram_dout),
    .delay_line(delay_line)
);


initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end

endmodule
