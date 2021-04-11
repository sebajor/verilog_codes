`include "msdft.v"
`include "rom.v"


module msdft_tb #(
    parameter DIN_WIDTH = 8,
    parameter DIN_POINT = 7,
    parameter TWIDD_WIDTH = 16,
    parameter TWIDD_POINT = 14,
    parameter DFT_LEN = 128,
    parameter DOUT_WIDTH = 32,
    parameter DOUT_POINT = 16
) (
    input wire clk,
    input wire rst,

    input wire [31:0] delay_line,

    input wire [DIN_WIDTH-1:0] din_re, din_im,
    input wire din_valid,
    

    output wire [DOUT_WIDTH-1:0] dout_re, dout_im,
    output wire dout_valid
);


wire [TWIDD_WIDTH-1:0] twidd_im, twidd_re;
wire [$clog2(DFT_LEN)-1:0] twidd_addr;
wire twidd_valid;

rom #(
    .N_ADDR(DFT_LEN),
    .DATA_WIDTH(2*TWIDD_WIDTH),
    .INIT_VALS("twidd_init.hex") 
) twidd_rom (
    .clk(clk),
    .ren(twidd_valid),
    .radd(twidd_addr),
    .wout({twidd_re, twidd_im}) //por como lo lee!
);



msdft #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .TWIDD_WIDTH(TWIDD_WIDTH),
    .TWIDD_POINT(TWIDD_POINT),
    .DFT_LEN(DFT_LEN),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT)
) msdft_inst (
    .clk(clk),
    .rst(rst),
    .delay_line(delay_line),
    .din_re(din_re),
    .din_im(din_im),
    .din_valid(din_valid),
    .twidd_im(twidd_im),
    .twidd_re(twidd_re),
    .twidd_addr(twidd_addr), 
    .twidd_valid(twidd_valid),
    .dout_re(dout_re), 
    .dout_im(dout_im),
    .dout_valid(dout_valid)
);

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();    
end

endmodule
