`default_nettype none 
`include "includes.v"

module msdft #(
    parameter DIN_WIDTH = 8,
    parameter DIN_POINT = 7,
    parameter TWIDD_WIDTH = 16,
    parameter TWIDD_POINT = 14,
    parameter TWIDD_FILE = "twidd.hex",
    parameter DFT_LEN = 128,
    parameter DOUT_WIDTH = 32,
    parameter DOUT_POINT = 16
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

reg [31:0] delay_line_r=(2**$clog2(DFT_LEN)-1);
always@(posedge clk)begin
    delay_line_r <= delay_line;
end


wire signed [DIN_WIDTH:0] comb_re, comb_im;
wire comb_valid;

comb #(
    .DIN_WIDTH(DIN_WIDTH),
    .DELAY_LINE(DFT_LEN),
    .DOUT_WIDHT(DIN_WIDTH+1)
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
    .DOUT_WIDHT(DIN_WIDTH+1)
) comb_im_inst (
    .clk(clk),
    .rst(rst),
    .din(din_im),
    .din_valid(din_valid),
    .delay_line(delay_line_r),
    .dout(comb_im),
    .dout_valid()
);

//signals to read twiddle factors
reg [$clog2(DFT_LEN)-1:0] twidd_addr=0;
wire [TWIDD_WIDTH-1:0] twidd_re, twidd_im;
reg twidd_valid=0;
reg signed [DIN_WIDTH:0] comb_re_r =0, comb_im_r=0;

always@(posedge clk)begin
    comb_re_r <= comb_re;
    comb_im_r <= comb_im;
    twidd_valid <= comb_valid;
    if(rst)
        twidd_addr <= 0;
    else if(comb_valid)begin
        if(twidd_addr==delay_line_r)
            twidd_addr <= 0;
        else
            twidd_addr <= twidd_addr+1;
    end
    else 
        twidd_addr <= twidd_addr;
end



async_true_dual_ram #(
    .RAM_WIDTH(2*TWIDD_WIDTH),
    .RAM_DEPTH(DFT_LEN),
    .RAM_PERFORMANCE("LOW_LATENCY"),
    .INIT_FILE(TWIDD_FILE)
)twidd_ram_inst (
    .clka(clk),
    .addra(twidd_addr),
    .dina(),
    .wea(1'b0),
    .ena(1'b1),
    .rsta(1'b0),
    .regcea(),
    .douta({twidd_re, twidd_im}),
    .clkb(axi_clock),
    .addrb(bram_addr),
    .dinb(bram_dat),
    .web(bram_we),
    .enb(1'b1),
    .rstb(1'b0),
    .regceb(),
    .doutb(bram_dout)
);

//complex multiplication, check the sync of the brams
localparam MULT_WIDTH = DIN_WIDTH+2+TWIDD_WIDTH;
localparam MULT_POINT = DIN_POINT+TWIDD_POINT;


wire signed [MULT_WIDTH-1:0] mult_re, mult_im;
wire mult_valid;


complex_mult #(
    .DIN1_WIDTH(DIN_WIDTH+1),
    .DIN2_WIDTH(TWIDD_WIDTH)
)complex_mult_inst (
    .clk(clk),
    //.din1_re(comb_re_r), 
    //.din1_im(comb_im_r),
    .din1_re(comb_re), 
    .din1_im(comb_im),
    .din2_re(twidd_re),
    .din2_im(twidd_im),
    .din_valid(twidd_valid),
    .dout_re(mult_re),
    .dout_im(mult_im),
    .dout_valid(mult_valid)
);


//integrator
localparam INTEG_WIDHT = MULT_WIDTH+$clog2(DFT_LEN);

reg signed [INTEG_WIDHT-1:0] integ_re=0, integ_im=0;
reg integ_valid=0;

always@(posedge clk)begin
    if(rst)begin
        integ_re <= 0; integ_im <= 0;
        integ_valid<=0;
    end
    else if(mult_valid)begin
        integ_re <= $signed(integ_re)+$signed(mult_re);
        integ_im <= $signed(integ_im)+$signed(mult_im);
        integ_valid <= 1;
    end
    else begin
        integ_re <= integ_re; integ_im <=integ_im;
        integ_valid <=0;
    end
end



signed_cast #(
    .DIN_WIDTH(INTEG_WIDHT),
    .DIN_POINT(MULT_POINT),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT)
)signed_integ_re (
    .clk(clk), 
    .din(integ_re),
    .din_valid(integ_valid),
    .dout(dout_re),
    .dout_valid(dout_valid)
);

signed_cast #(
    .DIN_WIDTH(INTEG_WIDHT),
    .DIN_POINT(MULT_POINT),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT)
)signed_integ_im (
    .clk(clk), 
    .din(integ_im),
    .din_valid(integ_valid),
    .dout(dout_im),
    .dout_valid()
);






endmodule
