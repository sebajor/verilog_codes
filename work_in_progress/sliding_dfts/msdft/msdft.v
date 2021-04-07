`default_nettype none
`include "complex_comb.v"

//TODO: change the rom for axi lite bram to modify the twiddle factors on the fly

module msdft #(
    parameter DIN_WIDTH = 8,
    parameter DIN_POINT = 7,
    parameter TWIDD_WIDTH = 16,
    parameter TWIDD_POINT = 14,
    parameter DFT_LEN = 128,
    parameter BIN_NUM = 3,
    parameter TWIDD_FILE = "twidd_data"
) (
    input wire clk,
    input wire rst,

    input wire [2*DIN_WIDTH-1:0] din,   //complex {re,im}
    input wire din_valid,

    output wire [2*(DIN_WIDTH+TWIDD_WIDTH+1+$clog2(DFT_LEN))-1:0] dout,
    output wire dout_valid
);

/*example how to charge multiple initial parameters to one module
https://stackoverflow.com/questions/17336636/generate-instance-with-different-string-parameters-in-verilog
*/

localparam COMB_WIDTH = DIN_WIDTH+1;

wire [2*(COMB_WIDTH)-1:0] comb_dout;    //complex {re,im} full scale output
wire comb_valid;
 
complex_comb #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .DELAY_LINE(DELAY_LINE)
) comb_inst (
    .clk(clk),
    .rst(rst),
    .din(din),
    .din_valid(din_valid),
    .dout(comb_dout),
    .dout_valid(comb_valid)
);

//pipeline the comb output 
reg [2*COMB_WIDTH-1:0] comb_r=0;
reg comb_valid_r=0;
always@(posedge clk)begin
    comb_r <= comb_dout;
    comb_valid_r <= comb_valid; 
end

//twiddle factors rom

rom #(
    N_ADDR = 256,
    DATA_WIDTH = 16,
    INIT_VALS = "w_1_15.mif"
) (
    clk,
    ren,
    [$clog2(N_ADDR)-1:0] radd,
    [DATA_WIDTH-1:0]  wout
);



endmodule
