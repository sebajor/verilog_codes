`default_nettype none

/*
*   Based on XAPP524
*   Introduce the data clock into a idelay configured in a variable mode and into
*   an iserdes that uses the delayed clock as the main clock.
*   The output of the iserdes goes into a state machine that checks if it gots
*   a good frame of data (pure 1's) otherwise change the idelay value.
*
*   This module generates the internal data_clk and the divided one. Also use the
*   frame clock to determine the bitslip.
*   For the 7-series the bitslip is integrated in the iserdes2.
*/

module clock_alignment #(
    parameter IOSTANDARD="LVDS_25",
    parameter BUFR_DIVIDE = "4"

) (
    input wire data_clock_p, data_clock_n,
    input wire frame_clock_p, frame_clock_n,

    input wire async_rst,
    input wire sync_rst,

    output wire data_clk_bufio,
    output wire data_clk_div,

    output wire iserdes2_bitslip,
    output wire [2:0] bitslip_count,
    output wire frame_valid
);

wire ibufds_clk;
wire data_clk_bufio_internal, data_clk_div_internal;


IBUFDS #(
    .IOSTANDARD(IOSTANDARD),
    .DIFF_TERM("TRUE")
) adc_dclk_ibufds (
    .I(data_clock_p),
    .IB(data_clock_n),
    .O(ibufds_clk)
);

BUFIO adc_clk_bufio (
    .I(ibufds_clk),
    .O(data_clk_bufio_internal)
);

BUFR #(
    .BUFR_DIVIDE(BUFR_DIVIDE)
) adc_clk_bufr (
    .I(ibufds_clk),
    .CE(1'b1),
    .CLR(async_rst),
    .O(data_clk_div_internal)
);

assign data_clk_bufio = data_clk_bufio_internal;
assign data_clk_div = data_clk_div_internal;

//
wire frame_clk, frame_clk_delayed;

IBUFDS #(
    .IOSTANDARD(IOSTANDARD),
    .DIFF_TERM("TRUE")
) fram_clk_ibufds (
    .I(frame_clock_p),
    .IB(frame_clock_n),
    .O(frame_clk)
);

IDELAYE2 #(
    .IDELAY_TYPE("FIXED"),
    .DELAY_SRC("IDATAIN"),
    .IDELAY_VALUE(14), // a value of 14 should give ~1.1ns with a 200MHz reference
    .HIGH_PERFORMANCE_MODE("TRUE"),
    .SIGNAL_PATTERN("DATA"),
    .REFCLK_FREQUENCY(200),
    .CINVCTRL_SEL("FALSE"),
    .PIPE_SEL("FALSE")
) frame_clock_idelay (
    .C(1'b0),
    .REGRST(1'b0),
    .LD(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .CINVCTRL(1'b0),
    .CNTVALUEIN(9'h0),
    .IDATAIN(frame_clk),
    .DATAIN(1'b0),
    .LDPIPEEN(1'b0),
    .DATAOUT(frame_clk_delayed),
    .CNTVALUEOUT()
);

//iserdes 


wire [7:0] frame_clk_data;
reg bitslip_internal=0;



ISERDESE2 #(
    .DATA_RATE("DDR"),
    .DATA_WIDTH(8),
    .INTERFACE_TYPE("NETWORKING"), // Using internal clock network routing
    .DYN_CLKDIV_INV_EN("FALSE"), // We do not need dynamic clocking
    .DYN_CLK_INV_EN("FALSE"), // We do not need dynamic clocking
    .NUM_CE(1), // Only use CE1 as a clock enable
    .OFB_USED("FALSE"), //
    .IOBDELAY("BOTH"),
    .SERDES_MODE("MASTER")
) frame_clock_iserdes (
    .Q1(frame_clk_data[0]),
    .Q2(frame_clk_data[1]),
    .Q3(frame_clk_data[2]),
    .Q4(frame_clk_data[3]),
    .Q5(frame_clk_data[4]),
    .Q6(frame_clk_data[5]),
    .Q7(frame_clk_data[6]),
    .Q8(frame_clk_data[7]),
    .O(),
    .SHIFTOUT1(),
    .SHIFTOUT2(),
    .D(1'b0),
    .DDLY(frame_clk_delayed),
    .CLK(data_clk_bufio_internal),
    .CLKB(~data_clk_bufio_internal),
    .CE1(1'b1),
    .CE2(1'b0),

    .RST(sync_rst),
    .CLKDIV(data_clk_div_internal),
    .CLKDIVP(1'b0),
    .OCLK(1'b0),
    .OCLKB(1'b0),
    .BITSLIP(bitslip_internal),
    .SHIFTIN1(1'b0),
    .SHIFTIN2(1'b0),
    .OFB(1'b0),
    .DYNCLKDIVSEL(1'b0),
    .DYNCLKSEL(1'b0)
);

//here we iterates changing the bitslip until you get a good singal
//this bitslip will be shared between the data iserdes also
reg [1:0] wait_counter=0;   //between each bitslip signal you have to wait 3 cycles
reg frame_valid_r=0;
reg [2:0] bitslip_counter_r=0;

always@(posedge data_clk_div_internal or posedge sync_rst)begin
    if(sync_rst)begin
        wait_counter <= 0;  
        frame_valid_r <=0;
        bitslip_internal <= 0;
        bitslip_counter_r <= 0;
    end
    else begin
        frame_valid_r <= 0;
        bitslip_internal <= 0;
        if((frame_clk_data != 8'b11110000) && (wait_counter==0))begin
            bitslip_internal <= 1;
            wait_counter <=3;
            bitslip_counter_r <= bitslip_counter_r+1;
        end
        else if(frame_clk_data==8'b11110000)begin
            frame_valid_r <= 1;
        end

        if(wait_counter >0)begin
            wait_counter <= wait_counter-1;
        end
    end
end


assign iserdes2_bitslip = bitslip_internal;
assign bitslip_count = bitslip_counter_r;
assign frame_valid = frame_valid_r;


endmodule
