`default_nettype none


/*
*   Note: by default we use 64 bits bram to store real-imag part of the twiddle 
*   factors. When reading from the fpga they are resized
*/


module dft_bin_multiple_inputs #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 15,
    parameter PARALLEL_INPUTS = 2,
    parameter TWIDD_WIDTH = 16,
    parameter TWIDD_POINT = 14,
    parameter TWIDD_FILE = "twidd_init.bin",
    parameter TWIDD_DELAY = 1,
    parameter AXI_DATA_WIDTH = 32,
    parameter ACC_DELAY = 0,
    parameter DFT_LEN = 128,
    parameter DOUT_WIDTH = 32,
    parameter DOUT_POINT = 15,
    parameter DOUT_DELAY = 1,
    parameter REAL_INPUT_ONLY=0,
    parameter CAST_WARNING = 1
) (
    input wire clk,
    input wire rst, 
    input wire [PARALLEL_INPUTS*DIN_WIDTH-1:0] din_re, din_im,
    input wire din_valid,
    
    input wire [31:0] delay_line,   //this controls the DFT size, the one at the parameter is the max value
    
    output wire [PARALLEL_INPUTS*DOUT_WIDTH-1:0] dout_re, dout_im, 
    output wire dout_valid,
    output wire cast_warning,
    //axilite interface
    input wire axi_clock,
    input wire axil_rst,
    //write address channel
    input wire [$clog2(DFT_LEN)+2:0] s_axil_awaddr,
    input wire [2:0] s_axil_awprot,
    input wire s_axil_awvalid,
    output wire s_axil_awready,
    //write data channel
    input wire [AXI_DATA_WIDTH-1:0] s_axil_wdata,
    input wire [(AXI_DATA_WIDTH)/8-1:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output wire s_axil_wready,
    //write response channel
    output wire [1:0] s_axil_bresp,
    output wire s_axil_bvalid,
    input wire s_axil_bready,
    //read address channel
    input wire [$clog2(DFT_LEN)+2:0] s_axil_araddr,
    input wire s_axil_arvalid,
    output wire s_axil_arready,
    input wire [2:0] s_axil_arprot,
    //read data channel
    output wire [(AXI_DATA_WIDTH)-1:0] s_axil_rdata,
    output wire [1:0] s_axil_rresp,
    output wire s_axil_rvalid,
    input wire s_axil_rready
);

reg [31:0] delay_line_r = DFT_LEN-1;


always@(posedge clk)begin
    delay_line_r <= delay_line;
end


reg [PARALLEL_INPUTS*DIN_WIDTH-1:0]  din_re_r=0, din_im_r=0;
reg [$clog2(DFT_LEN)-1:0] twidd_addr;
reg twidd_valid = 0;

always@(posedge clk)begin
    din_re_r <= din_re;
    din_im_r <= din_im;
    twidd_valid <= din_valid;
    if(rst)
        twidd_addr <= 0;
    else if(din_valid)begin
        if(twidd_addr==delay_line_r)
            twidd_addr<= 0;
        else
            twidd_addr<= twidd_addr+1;
    end
end

//we are going to use an unbalanced bram and need to calculate the compatible axi size
wire [31:0] bram_re_out, bram_im_out;
wire signed [TWIDD_WIDTH-1:0] twidd_re, twidd_im;


axil_bram_unbalanced #(
    .FPGA_DATA_WIDTH(64),
    .FPGA_ADDR_WIDTH($clog2(DFT_LEN)),
    .AXI_DATA_WIDTH(32),
	.INIT_FILE(TWIDD_FILE)
) twiddle_factors_bram (
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
    .bram_din(),
    .bram_addr(twidd_addr),
    .bram_we(1'b0),
    .bram_dout({bram_im_out, bram_re_out})
);


//now we have to cast them to its actual size
assign twidd_re = bram_re_out[0+:TWIDD_WIDTH];
assign twidd_im = bram_im_out[0+:TWIDD_WIDTH];


localparam MULT_WIDTH = DIN_WIDTH+TWIDD_WIDTH+1;
localparam MULT_POINT = DIN_POINT+TWIDD_POINT;
localparam ACC_WIDTH = MULT_WIDTH+$clog2(DFT_LEN);
genvar i;
generate
    for(i=0; i<PARALLEL_INPUTS; i=i+1)begin:loop
        wire signed [DIN_WIDTH-1:0] din_re_internal, din_im_internal;
        wire signed [TWIDD_WIDTH-1:0] twidd_re_internal, twidd_im_internal;
        wire twidd_valid_internal;
        delay #(
            .DATA_WIDTH(2*TWIDD_WIDTH+2*DIN_WIDTH+1),
            .DELAY_VALUE(TWIDD_DELAY)
        ) twidd_delay_inst (
            .clk(clk),
            .din({din_re_r[DIN_WIDTH*i+:DIN_WIDTH], din_im_r[DIN_WIDTH*i+:DIN_WIDTH], 
                 twidd_re, twidd_im, twidd_valid}),
            .dout({din_re_internal, din_im_internal,
                   twidd_re_internal, twidd_im_internal, twidd_valid_internal})
        );

        wire [MULT_WIDTH-1:0] mult_re, mult_im;
        wire mult_valid;

        complex_mult #(
            .DIN1_WIDTH(DIN_WIDTH),
            .DIN2_WIDTH(TWIDD_WIDTH)
        )complex_mult_inst (
            .clk(clk),
            .din1_re(din_re_internal), 
            .din1_im(din_im_internal),
            .din2_re(twidd_re_internal),
            .din2_im(twidd_im_internal),
            .din_valid(twidd_valid_internal),
            .dout_re(mult_re),
            .dout_im(mult_im),
            .dout_valid(mult_valid)
        );

        wire signed [ACC_WIDTH-1:0] acc_re, acc_im;
        reg acc_valid =0;
        reg [$clog2(DFT_LEN)-1:0] acc_counter=0;
        wire [1:0] acc_out_valid;

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
        wire signed [MULT_WIDTH-1:0] mult_re_r, mult_im_r;
        wire mult_valid_r, acc_valid_r;

        delay #(
            .DATA_WIDTH(2*MULT_WIDTH+2),
            .DELAY_VALUE(ACC_DELAY)
        ) acc_delay_inst (
            .clk(clk),
            .din({mult_re, mult_im, mult_valid, acc_valid}),
            .dout({mult_re_r, mult_im_r, mult_valid_r, acc_valid_r})
        );

        scalar_accumulator #(
            .DIN_WIDTH(MULT_WIDTH),
            .ACC_WIDTH(ACC_WIDTH),
            .DATA_TYPE("signed")
        ) dft_accumulator_inst [1:0](
            .clk(clk),
            .din({mult_re_r, mult_im_r}),
            .din_valid(mult_valid_r),
            .acc_done(acc_valid_r),
            .dout({acc_re, acc_im}),
            .dout_valid(acc_out_valid)
        );

        //THIS PART BROKE THE SIMULATION!!!
        wire [DOUT_WIDTH-1:0] dout_cast_re, dout_cast_im;
        wire [1:0] dout_cast_valid;
        wire [1:0] dout_re_cast_ovf, dout_im_cast_ovf;

        signed_cast #(
            .DIN_WIDTH(ACC_WIDTH),
            .DIN_POINT(MULT_POINT),
            .DOUT_WIDTH(DOUT_WIDTH),
            .DOUT_POINT(DOUT_POINT),
            .OVERFLOW_WARNING(CAST_WARNING)
        ) dout_cast [1:0] (
            .clk(clk), 
            .din({acc_re, acc_im}),
            .din_valid(acc_out_valid[0]),
            .dout({dout_cast_re, dout_cast_im}),
            .dout_valid(dout_cast_valid),
            .warning({dout_re_cast_ovf, dout_im_cast_ovf})
        );
        
        assign dout_re[DOUT_WIDTH*i+:DOUT_WIDTH] = dout_cast_re;
        assign dout_im[DOUT_WIDTH*i+:DOUT_WIDTH] = dout_cast_im;
    end
endgenerate

assign dout_valid = loop[0].dout_cast_valid[0];

endmodule
