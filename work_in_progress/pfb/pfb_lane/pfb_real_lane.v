`default_nettype none

/*

    For a parallel input stream data the actual size of the window is 
    TAPS*PFB_SIZE*PARALLEL, then each sub-filter got TAPS*PFB_SIZE
*/


module pfb_real_lane #(
    parameter DIN_WIDTH = 8,
    parameter DIN_POINT = 7,
    parameter TAPS = 4,      //like im indexing using ascii 9 is the top number of taps
    parameter PFB_SIZE = 64, //for wola-fft should be the same as size of the FFT
    parameter COEFF_WIDTH = 18,
    parameter COEFF_POINT = 17,
    parameter COEFF_FILE = "",
    parameter DOUT_WIDTH = 18,
    parameter DOUT_POINT = 17,
    parameter PRE_MULT_LATENCY = 2,
    parameter MULT_LATENCY = 1,
    parameter DOUT_SHIFT = 0,
    parameter DOUT_DELAY = 0,
    parameter DEBUG = 0
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din,
    input wire din_valid,
    input wire sync_in, 

    output wire signed [DOUT_WIDTH-1:0] dout,
    output wire dout_valid,
    output wire sync_out,
    output wire ovf_flag
);

reg [$clog2(PFB_SIZE*TAPS)-1:0] rom_addr=0, rom_addr_r=0;

always@(posedge clk)begin
    rom_addr_r <= rom_addr;
    if(sync_in)
        rom_addr <=0;
    else
        rom_addr <= rom_addr+1;
end


//each addr of the rom has TAPS coefficients, eg if taps=4 the first address will
//have the the coeffs 0 to 3, the second address the 4-7, etc

wire signed [TAPS*COEFF_WIDTH-1:0] coeffs;
genvar j;
generate 
    for(j=0; j<TAPS; j=j+1)begin
        localparam integer temp=48+i;   //
        localparam rom_text = {COEFF_FILE,"_",temp};
        rom #(
            .N_ADDR(PFB_SIZE),
            .DATA_WIDTH(COEFF_WIDTH),
            .INIT_VALS(COEFF_FILE)
        ) coeff_rom (
            .clk(clk),
            .ren(1'b1),
            .radd(rom_addr_r),
            .wout(coeffs[COEFF_WIDTH*j+:COEFF_WIDTH])
        );
    end
endgenerate


wire signed [DIN_WIDTH-1:0] din_r;
wire sync_rom;
delay #(
    .DATA_WIDTH(DIN_WIDTH+1),
    .DELAY_VALUE(3)
) rom_delay (
    .clk(clk),
    .din({din, sync_in}),
    .dout({din_r, sync_rom})
);

localparam TAP_DOUT_WIDTH = (COEFF_WIDTH+DIN_WIDTH);
localparam TAP_DOUT_POINT = (COEFF_POINT+DIN_POINT);

wire [TAP_DOUT_WIDTH*TAPS-1:0] tap_dout;
genvar i;
generate 
    for(i=0; i<TAPS-1; i=i+1)begin: loop
        wire loop_sync_out;
        wire [COEFF_WIDTH*(TAPS-1-i)-1:0] loop_coeffs;
        wire [TAP_DOUT_WIDTH-1:0] loop_tap_dout;
        wire [DIN_WIDTH-1:0] loop_dout;
        assign tap_dout[TAP_DOUT_WIDTH*i+:TAP_DOUT_WIDTH] = loop_tap_dout;
        if(i==0)begin
            pfb_real_tap #(
                .DIN_WIDTH(DIN_WIDTH),
                .DIN_POINT(DIN_POINT),
                .COEFF_WIDTH(COEFF_WIDTH),
                .COEFF_POINT(COEFF_POINT),
                .TOTAL_TAPS(TAPS),
                .PFB_SIZE(PFB_SIZE),
                .TAP_NUMBER(i),
                .PRE_MULT_LATENCY(PRE_MULT_LATENCY),
                .MULT_LATENCY(MULT_LATENCY)
            ) pfb_tap_inst (
                .clk(clk),
                .din(din),
                .sync_in(sync_in),
                .coeff_in(coeffs),
                .dout(loop_dout),
                .sync_out(loop_sync_out),
                .coeff_out(loop_coeffs),
                .tap_dout(loop_tap_dout)
            );
        end
        else begin
            pfb_real_tap #(
                .DIN_WIDTH(DIN_WIDTH),
                .DIN_POINT(DIN_POINT),
                .COEFF_WIDTH(COEFF_WIDTH),
                .COEFF_POINT(COEFF_POINT),
                .TOTAL_TAPS(TAPS),
                .PFB_SIZE(PFB_SIZE),
                .TAP_NUMBER(i),
                .PRE_MULT_LATENCY(PRE_MULT_LATENCY),
                .MULT_LATENCY(MULT_LATENCY)
            ) pfb_tap_inst (
                .clk(clk),
                .din(loop[i-1].loop_dout),
                .sync_in(loop[i-1].loop_sync_out),
                .coeff_in(loop[i-1].loop_coeffs),
                .dout(loop_dout),
                .sync_out(loop_sync_out),
                .coeff_out(loop_coeffs),
                .tap_dout(loop_tap_dout)
            );
        end
    end
endgenerate

//make the last tap here
//check!!!
localparam LAST_INDEX = TAPS-2;
wire signed [COEFF_WIDTH-1:0] last_coeff = loop[LAST_INDEX].loop_coeffs;
wire signed [DIN_WIDTH-1:0] last_din = loop[LAST_INDEX].loop_dout;
wire last_sync = loop[LAST_INDEX].loop_sync_out;

wire signed [DIN_WIDTH-1:0] mult_din;
wire signed [COEFF_WIDTH-1:0] mult_coeff;

delay #(
    .DATA_WIDTH(DIN_WIDTH+COEFF_WIDTH),
    .DELAY_VALUE(PRE_MULT_LATENCY)
) pre_mult_delay(
    .clk(clk),
    .din({last_din, last_coeff}),
    .dout({mult_din, mult_coeff})
);

reg signed [DIN_WIDTH+COEFF_WIDTH-1:0] mult_out=0;
always@(posedge clk)begin
    mult_out <= $signed(mult_din)*$signed(mult_coeff);
end

wire [DIN_WIDTH+COEFF_WIDTH-1:0] last_tap_dout;

delay #(
    .DATA_WIDTH(DIN_WIDTH+COEFF_WIDTH),
    .DELAY_VALUE(MULT_LATENCY)
) mult_delay(
    .clk(clk),
    .din(mult_out),
    .dout(last_tap_dout)
);

//delay of the sync signal
wire tap_sync;
delay #(
    .DATA_WIDTH(1),
    .DELAY_VALUE(PRE_MULT_LATENCY+MULT_LATENCY+1)   //check!
) sync_delay(
    .clk(clk),
    .din(last_sync),
    .dout(tap_sync)
);


//adder tree for the tap outputs 
assign tap_dout[TAP_DOUT_WIDTH*(LAST_INDEX+1)+:TAP_DOUT_WIDTH] = last_tap_dout;

wire [TAP_DOUT_WIDTH+$clog2(TAPS)-1:0] add_dout;
wire add_sync;

adder_tree #(
    .DATA_WIDTH(TAP_DOUT_WIDTH),
    .PARALLEL(TAPS),
    .DATA_TYPE("signed")
) adder_tree_inst (
    .clk(clk),
    .din(tap_dout),
    .din_valid(tap_sync),
    .dout(add_dout),
    .dout_valid(add_sync)
);



resize_data #(
    .DIN_WIDTH(TAP_DOUT_WIDTH+$clog2(TAPS)),
    .DIN_POINT(TAP_DOUT_POINT),
    .DATA_TYPE("signed"),
    .PARALLEL(1),
    .SHIFT(DOUT_SHIFT),
    .DELAY(DOUT_DELAY),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT),
    .DEBUG(DEBUG)
) resize_inst (
    .clk(clk), 
    .din(add_dout),
    .din_valid(),
    .sync_in(add_sync),
    .dout(dout),
    .dout_valid(),
    .sync_out(sync_out),
    .warning()
);



endmodule
