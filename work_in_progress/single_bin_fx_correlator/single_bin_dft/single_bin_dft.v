`default_nettype none

/*
*   Author: Sebastian Jorquera
*   Single bin DFT by definition
*/

module single_bin_dft #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 15,
    parameter TWIDD_WIDTH = 16,
    parameter TWIDD_POINT = 14,
    parameter TWIDD_FILE = "twidd_init.bin",
    parameter DFT_LEN = 128,
    parameter DOUT_WIDTH = 32,
    parameter DOUT_POINT = 15,
    parameter DOUT_DELAY = 1,
    parameter CAST_WARNING = 1
) (
    input wire clk,
    input wire rst, 
    input wire signed [DIN_WIDTH-1:0] din_re, din_im,
    input wire din_valid,
    
    input wire [31:0] delay_line,   //this controls the DFT size, the one at the parameter is the max value
    
    output wire [DOUT_WIDTH-1:0] dout_re, dout_im, 
    output wire dout_valid,
    output wire cast_warning,
    //axilite interface
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

//axil bram with the twiddle factors

//signals to read twiddle factors
reg [DIN_WIDTH-1:0] din_re_r=0, din_im_r=0;
reg [$clog2(DFT_LEN)-1:0] twidd_addr=0;
wire [TWIDD_WIDTH-1:0] twidd_re, twidd_im;
reg twidd_valid=0;


always@(posedge clk)begin
    din_re_r <= din_re;
    din_im_r <= din_im;
    twidd_valid <= din_valid;
    if(rst)
        twidd_addr <= 0;
    else if(din_valid)begin
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
localparam MULT_WIDTH = DIN_WIDTH+TWIDD_WIDTH+1;
localparam MULT_POINT = DIN_POINT+TWIDD_POINT;


wire signed [MULT_WIDTH-1:0] mult_re, mult_im;
wire mult_valid;


complex_mult #(
    .DIN1_WIDTH(DIN_WIDTH),
    .DIN2_WIDTH(TWIDD_WIDTH)
)complex_mult_inst (
    .clk(clk),
    .din1_re(din_re_r), 
    .din1_im(din_im_r),
    .din2_re(twidd_re),
    .din2_im(twidd_im),
    .din_valid(twidd_valid),
    .dout_re(mult_re),
    .dout_im(mult_im),
    .dout_valid(mult_valid)
);

localparam ACC_WIDTH = MULT_WIDTH+$clog2(DFT_LEN);
wire signed [ACC_WIDTH-1:0] acc_re, acc_im;
reg acc_valid=0;
reg [$clog2(DFT_LEN)-1:0] acc_counter=0;
wire acc_out_valid;

always@(posedge clk)begin
    if(rst)begin
        acc_counter<=0;
        acc_valid<=0;
    end
    else if(mult_valid)begin
        if(acc_counter==(delay_line_r))begin
            //check!!!
            acc_valid <= 1;
            acc_counter <= 0;
        end
        else begin
            acc_valid <=0;
            acc_counter <= acc_counter+1;
        end
    end
end


scalar_accumulator #(
    .DIN_WIDTH(MULT_WIDTH),
    .ACC_WIDTH(ACC_WIDTH),
    .DATA_TYPE("signed")
) dft_accumulator_inst [1:0](
    .clk(clk),
    .din({mult_re, mult_im}),
    .din_valid(mult_valid),
    .acc_done(acc_valid),
    .dout({acc_re, acc_im}),
    .dout_valid(acc_out_valid)
);


wire [DOUT_WIDTH-1:0] dout_cast_re, dout_cast_im;
wire dout_cast_valid;

signed_cast #(
    .DIN_WIDTH(ACC_WIDTH),
    .DIN_POINT(MULT_POINT),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT)
) dout_cast [1:0] (
    .clk(clk), 
    .din({acc_re, acc_im}),
    .din_valid(acc_out_valid),
    .dout({dout_cast_re, dout_cast_im}),
    .dout_valid(dout_cast_valid)
);

delay #(
    .DATA_WIDTH(2*DOUT_WIDTH+1),
    .DELAY_VALUE(DOUT_DELAY)
) dout_delay (
    .clk(clk),
    .din({dout_cast_re, dout_cast_im, dout_cast_valid}),
    .dout({dout_re, dout_im, dout_valid})
);


endmodule
