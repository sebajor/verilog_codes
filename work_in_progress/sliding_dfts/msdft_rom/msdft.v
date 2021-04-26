`default_nettype none
`include "comb.v"
`include "complex_mult.v"
`include "signed_cast.v"

/* Only one msdft.. in theory we could use one comb and then 
instantiate the multiplier and the resonator for each twiddle factor

Also 
*/

module msdft #(
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
    
    input wire [TWIDD_WIDTH-1:0] twidd_im, twidd_re,
    output wire [$clog2(DFT_LEN)-1:0] twidd_addr, 
    output wire twidd_valid,

    output wire [DOUT_WIDTH-1:0] dout_re, dout_im,
    output wire dout_valid
);

reg [31:0] delay_line_r;
always@(posedge clk)begin
    delay_line_r <=delay_line;
end


wire [DIN_WIDTH:0] comb_re, comb_im;
wire comb_valid;

comb #(
    .DIN_WIDTH(DIN_WIDTH),
    .DELAY_LINE(DFT_LEN),
    .DOUT_WIDTH(DIN_WIDTH+1)
) comb_re_inst (
    .clk(clk),
    .rst(rst),
    .din(din_re),
    .din_valid(din_valid),
    .delay_line(delay_line_r),
    .dout(comb_re),
    .dout_valid(comb_valid)
);


comb #(
    .DIN_WIDTH(DIN_WIDTH),
    .DELAY_LINE(DFT_LEN),
    .DOUT_WIDTH(DIN_WIDTH+1)
) comb_im_inst (
    .clk(clk),
    .rst(rst),
    .din(din_im),
    .din_valid(din_valid),
    .delay_line(delay_line_r),
    .dout(comb_im),
    .dout_valid()
);

//create the signals to read the twiddle factors
//check the timing of the read of the brams!
reg [$clog2(DFT_LEN)-1:0] twidd_address=0;
reg twidd_valid_r=0;
reg [DIN_WIDTH:0] comb_re_r=0, comb_im_r=0;
always@(posedge clk)begin
    //check the delays in the reading!
    comb_re_r <= comb_re;
    comb_im_r <= comb_im;
    twidd_valid_r<= comb_valid;
    if(rst) begin
        twidd_address<=0;
    end
    else if(comb_valid)begin
        if(twidd_address==delay_line_r)
            twidd_address <=0;
        else
            twidd_address <= twidd_address+1;
    end
    else begin
        twidd_address <= twidd_address; 
    end
end

assign twidd_addr = twidd_address;
assign twidd_valid = comb_valid;    //check!!



//modulation
wire signed [(DIN_WIDTH+1+TWIDD_WIDTH):0] mod_re, mod_im;
wire mod_valid;

complex_mult #(
    .DIN1_WIDTH(DIN_WIDTH+1),
    .DIN2_WIDTH(TWIDD_WIDTH)
) complex_mult_inst (
    .clk(clk),
    .din1_re(comb_re_r),
    .din1_im(comb_im_r),
    .din2_re(twidd_re),
    .din2_im(twidd_im),
    .din_valid(twidd_valid_r),
    .dout_re(mod_re),
    .dout_im(mod_im),
    .dout_valid(mod_valid)
);

//I think if I cast the multiplication output there are elimination problems
//with the comb+integrator in the design ie it becomes unstable
localparam MOD_WIDTH = DIN_WIDTH+1+TWIDD_WIDTH+1;
localparam MOD_POINT = DIN_POINT+TWIDD_POINT;
//localparam INTEG_WIDHT = MOD_WIDTH+$clog2(DFT_LEN);   //ise cries about using clog2 in localparam >:(
parameter INTEG_WIDHT = MOD_WIDTH+$clog2(DFT_LEN);
localparam INTEG_INT = INTEG_WIDHT-MOD_POINT;

//integrator
reg signed [INTEG_WIDHT-1:0] integ_re=0, integ_im=0;
reg integ_valid=0;
always@(posedge clk)begin
    if(rst)begin
        integ_re<=0; integ_im<=0;
        integ_valid <=0;
    end
    else if(mod_valid)begin
        integ_re <= $signed(integ_re)+$signed(mod_re);
        integ_im <= $signed(integ_im)+$signed(mod_im);
        integ_valid <=1;
    end
    else begin
        integ_valid <=0;
        integ_re<= integ_re; integ_im<=integ_im;
    end
end

//cast the integrator to DOUT_WIDTH
localparam DOUT_INT = DOUT_WIDTH-DOUT_POINT;

signed_cast #(
    .PARALLEL(2),
    .DIN_WIDTH(INTEG_WIDHT), 
    .DIN_INT(INTEG_INT), 
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_INT(DOUT_INT)
) dout_cast (
    .clk(clk),
    .din({integ_im, integ_re}),
    .din_valid(integ_valid),
    .dout({dout_im, dout_re}),
    .dout_valid(dout_valid)
);


endmodule
