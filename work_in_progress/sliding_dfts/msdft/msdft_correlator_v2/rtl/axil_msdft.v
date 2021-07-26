`default_nettype none

module axil_msdft #(
    parameter DIN_WIDTH = 8,
    parameter DIN_POINT = 7,
    parameter TWIDD_WIDTH = 16, //this is limited by the axi intf... check how to change it
    parameter TWIDD_POINT = 14,
    parameter TWIDD_FILE = "twidd_init.hex",
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

    //delay line configuration
    input wire [31:0] delay_line,

    //axil signals
    input wire axi_clock,
    input wire axil_rst,
    //write address channel
    input wire [$clog2(DFT_LEN)+1:0] s_axil_awaddr,
    input wire [2:0] s_axil_awprot,
    input wire s_axil_awvalid,
    output wire s_axil_awready,
    //write data channel
    input wire [2*TWIDD_WIDTH-1:0] s_axil_wdata,
    input wire [(2*TWIDD_WIDTH)/8-1:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output wire s_axil_wready,
    //write response channel
    output wire [1:0] s_axil_bresp,
    output wire s_axil_bvalid,
    input wire s_axil_bready,
    //read address channel
    input wire [$clog2(DFT_LEN)+1:0] s_axil_araddr,
    input wire s_axil_arvalid,
    output wire s_axil_arready,
    input wire [2:0] s_axil_arprot,
    //read data channel
    output wire [(2*TWIDD_WIDTH)-1:0] s_axil_rdata,
    output wire [1:0] s_axil_rresp,
    output wire s_axil_rvalid,
    input wire s_axil_rready
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






axil_bram #(
    .DATA_WIDTH(2*TWIDD_WIDTH),        
    .ADDR_WIDTH($clog2(DFT_LEN)),
    .INIT_FILE(TWIDD_FILE)
) twidd_ram_inst (
    .axi_clock(axi_clock),
    .rst(axil_rst),
    .s_axil_awaddr(s_axil_awaddr),
    .s_axil_awprot(s_axil_awprot),
    .s_axil_awvalid(s_axil_awvalid),
    .s_axil_awready(s_axil_awready),
    .s_axil_wdata(s_axil_wdata),
    .s_axil_wstrb(s_axil_wstrb),
    .s_axil_wvalid(s_axil_wvalid),
    .s_axil_wready(s_axil_wready),
    .s_axil_bresp(s_axil_bresp),
    .s_axil_bvalid(s_axil_bvalid),
    .s_axil_bready(s_axil_bready),
    .s_axil_araddr(s_axil_araddr),
    .s_axil_arvalid(s_axil_arvalid),
    .s_axil_arready(s_axil_arready),
    .s_axil_arprot(s_axil_arprot),
    .s_axil_rdata(s_axil_rdata),
    .s_axil_rresp(s_axil_rresp),
    .s_axil_rvalid(s_axil_rvalid),
    .s_axil_rready(s_axil_rready),
    .fpga_clk(clk),
    .bram_din(32'd0),
    .bram_addr(twidd_addr),
    .bram_we(1'b0),
    .bram_dout({twidd_re, twidd_im})
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
