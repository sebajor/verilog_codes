`default_nettype none

/*
*   This is an exact copy of the casper tap block, that reason that you wet all 
*   the coeff in.
*/
module pfb_real_tap #(
    parameter DIN_WIDTH = 8,
    parameter DIN_POINT = 7,
    parameter COEFF_WIDTH = 18,
    parameter COEFF_POINT = 17,
    parameter TOTAL_TAPS = 2,
    parameter PFB_SIZE = 64,
    parameter TAP_NUMBER=0,  //it range (0 to TOTAL_TAPS-1) but the last one will cause an error so its handled in the pfb_lane
    parameter PRE_MULT_LATENCY = 2,
    parameter MULT_LATENCY = 1
) (
    input wire clk,
    input wire [DIN_WIDTH-1:0] din,
    input wire sync_in,
    input wire [COEFF_WIDTH*(TOTAL_TAPS-TAP_NUMBER)-1:0] coeff_in,

    output wire [DIN_WIDTH-1:0] dout,
    output wire sync_out,
    output wire [COEFF_WIDTH*(TOTAL_TAPS-TAP_NUMBER-1)-1:0] coeff_out,
    output wire [COEFF_WIDTH+DIN_WIDTH-1:0] tap_dout
);


//the actual useful coefficient is at the bottom
wire signed [COEFF_WIDTH-1:0] coeff = coeff_in[0+:COEFF_WIDTH];
assign coeff_out = coeff_in[COEFF_WIDTH*(TOTAL_TAPS-TAP_NUMBER)-1:COEFF_WIDTH];

//the multiplication 
wire signed [DIN_WIDTH-1:0] mult_din;
wire signed [COEFF_WIDTH-1:0] mult_coeff;

delay #(
    .DATA_WIDTH(DIN_WIDTH+COEFF_WIDTH),
    .DELAY_VALUE(PRE_MULT_LATENCY)
) pre_mult_delay(
    .clk(clk),
    .din({din, coeff}),
    .dout({mult_din, mult_coeff})
);

reg signed [DIN_WIDTH+COEFF_WIDTH-1:0] mult_out=0;
always@(posedge clk)begin
    mult_out <= $signed(mult_din)*$signed(mult_coeff);
end

delay #(
    .DATA_WIDTH(DIN_WIDTH+COEFF_WIDTH),
    .DELAY_VALUE(MULT_LATENCY)
) mult_delay(
    .clk(clk),
    .din(mult_out),
    .dout(tap_dout)
);

//delay of the sync signal
delay #(
    .DATA_WIDTH(1),
    .DELAY_VALUE(TOTAL_TAPS*PFB_SIZE)   //check!
) sync_delay(
    .clk(clk),
    .din(sync_in),
    .dout(sync_out)
);

//buffer
reg [$clog2(PFB_SIZE)-1:0] buffer_counter=0;
always@(posedge clk)
    buffer_counter <= buffer_counter+1;

single_port_ram_read_first #(
    .RAM_WIDTH(DIN_WIDTH),
    .RAM_DEPTH(PFB_SIZE),
    .RAM_PERFORMANCE("HIGH_PERFORMANCE")
) single_port_ram_inst (
    .addra(buffer_counter),
    .dina(din),
    .clka(clk),
    .wea(1'b1),
    .ena(1'b1),
    .rsta(1'b0),
    .regcea(1'b1),
    .douta(dout)
);

endmodule
