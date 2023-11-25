`default_nettype none
`include "../primitives.v"

module clock_alignment #(
    parameter ADC_BITS = 14,
    parameter IOSTANDARD = "LVDS"
)(
    input wire data_clock_p, data_clock_n,
    input wire frame_clock_p, frame_clock_n,

    input wire async_rst,
    input wire sync_rst,

    input wire enable,

    output wire data_clk_bufio,
    output wire data_clk_div,

    output wire iserdes2_bitslip,
    output wire [3:0] bitslip_count,
    output wire frame_valid
);
    

wire ibufds_clk;
wire data_clk_bufio_internal, data_clk_div_internal;


IBUFDS #(
    .IOSTANDARD(IOSTANDARD ),
    .DIFF_TERM("TRUE")
) adc_dclk_ibufds (
    .I(data_clock_p),
    .IB(data_clock_n),
    .O(ibufds_clk)
);

wire mmcm_clkfb;
wire mmcm_clk_int;
wire mmcm_clkfb_bufg;


generate 
    if(ADC_BITS==14)begin
        //he enters with a 500MHz clock 
        //the vco is set at 500*2.5=1250mhz the outputs are then
        //clk0 = 500
        //clk1 = 125
        //I think the phase in the clkfbout is to generate a delay with respect the data
        MMCME4_BASE #(
            .BANDWIDTH("OPTIMIZED"),   // Jitter programming (OPTIMIZED, HIGH, LOW)
            .CLKFBOUT_MULT_F(2.5),     // Multiply value for all CLKOUT (2.000-64.000).
            .CLKFBOUT_PHASE(-126.000), // Phase offset in degrees of CLKFB (-360.000-360.000).
            .CLKIN1_PERIOD(2),         // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
            .CLKOUT0_DIVIDE_F(2.5),    // Divide amount for CLKOUT0 (1.000-128.000).
            .CLKOUT1_DIVIDE(10),       // Divide amount for CLKOUT1
            .CLKOUT0_PHASE(0.0),       // Phase offset for each CLKOUT (-360.000-360.000).
            .DIVCLK_DIVIDE(1),         // Master division value (1-106)
            .REF_JITTER1(0.0),         // Reference input jitter in UI (0.000-0.999).
            .STARTUP_WAIT("FALSE")     // Delays DONE until MMCM is locked (FALSE, TRUE)
        ) mmcm_dclk (
            .CLKOUT0(data_clk_bufio_internal),   // 1-bit output: CLKOUT0
            .CLKOUT1(data_clk_div_internal),     // 1-bit output: CLKOUT0
            .CLKFBOUT(mmcm_clkfb),    // 1-bit output: Feedback clock
            .LOCKED(),                 // 1-bit output: LOCK
            .CLKIN1(ibufds_clk),      // 1-bit input: Clock
            .RST(1'b0),                // 1-bit input: Reset
            .CLKFBIN(mmcm_clkfb_bufg) // 1-bit input: Feedback clock
        ); 
    end
    else if(ADC_BITS==12)begin
        MMCME4_BASE #(
            .BANDWIDTH("OPTIMIZED"),   // Jitter programming (OPTIMIZED, HIGH, LOW)
            .CLKFBOUT_MULT_F(7.5),     // Multiply value for all CLKOUT (2.000-64.000).
            .CLKFBOUT_PHASE(0.000), // Phase offset in degrees of CLKFB (-360.000-360.000).
            .CLKIN1_PERIOD(6.250),         // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
            .CLKOUT0_DIVIDE_F(7.5),    // Divide amount for CLKOUT0 (1.000-128.000).
            .CLKOUT1_DIVIDE(30),       // Divide amount for CLKOUT1
            .CLKOUT0_PHASE(0.0),       // Phase offset for each CLKOUT (-360.000-360.000).
            .DIVCLK_DIVIDE(1),         // Master division value (1-106)
            .REF_JITTER1(0.0),         // Reference input jitter in UI (0.000-0.999).
            .STARTUP_WAIT("FALSE")     // Delays DONE until MMCM is locked (FALSE, TRUE)
        )
        mmcm_dclk (
            .CLKOUT0(data_clk_bufio_internal),   // 1-bit output: CLKOUT0
            .CLKOUT1(data_clk_div_internal),     // 1-bit output: CLKOUT0
            .CLKFBOUT(mmcm_clkfb),    // 1-bit output: Feedback clock
            .LOCKED(),                 // 1-bit output: LOCK
            .CLKIN1(ibufds_clk),      // 1-bit input: Clock
            .RST(1'b0),                // 1-bit input: Reset
            .CLKFBIN(mmcm_clkfb_bufg) // 1-bit input: Feedback clock
        );
    end
endgenerate

BUFG  mmcmfb_bufg (
    .I(mmcm_clkfb),
    .O(mmcm_clkfb_bufg)
);



assign data_clk_bufio = data_clk_bufio_internal;
assign data_clk_div = data_clk_div_internal;


//we have to wait at 4 cycles between bitslip
reg [2:0] wait_counter =0;
reg frame_valid_r=0;


always@(posedge data_clk_div_internal or posedge sync_rst)begin
    if(sync_rst)begin
        frame_valid_r <=0;
        wait_counter <= 0;
    end
    else if(enable)begin
        if(wait_counter !=4)begin
            wait_counter <= wait_counter +1;
            frame_valid_r <= 0;
        end
        else 
            frame_valid_r <= 1;
    end
    else begin
        frame_valid_r <= 0;
    end
end

//bitslip phy
wire frame_clk;

IBUFDS #(
    .IOSTANDARD(IOSTANDARD),
    .DIFF_TERM("TRUE")
) frame_clk_ibufds (
    .I(frame_clock_p),
    .IB(frame_clock_n),
    .O(frame_clk)
);

//iserdes
wire [7:0] frame_clk_data;

ISERDESE3 #(
      .DATA_WIDTH(8),                 // Parallel data width (4,8)
      .FIFO_ENABLE("FALSE"),          // Enables the use of the FIFO
      .FIFO_SYNC_MODE("FALSE"),       // Always set to FALSE. TRUE is reserved for later use.
      .IS_CLK_B_INVERTED(1'b1),       // Optional inversion for CLK_B
      .IS_CLK_INVERTED(1'b0),         // Optional inversion for CLK
      .IS_RST_INVERTED(1'b0),         // Optional inversion for RST
      .SIM_DEVICE("ULTRASCALE_PLUS")  // Set the device version for simulation functionality (ULTRASCALE,
   )
   frame_clk_iserdes (
      .FIFO_EMPTY(),            // 1-bit output: FIFO empty flag
      .INTERNAL_DIVCLK(),       // 1-bit output: Internally divided down clock used when FIFO is
                                // disabled (do not connect)
      .Q(frame_clk_data),         // 8-bit registered output
      .CLK(data_clk_bufio_internal),      // 1-bit input: High-speed clock
      .CLKDIV(data_clk_div_internal),        // 1-bit input: Divided Clock
      .CLK_B(data_clk_bufio_internal),    // 1-bit input: Inversion of High-speed clock CLK
      .D(frame_clk),          // 1-bit input: Serial Data Input
      .FIFO_RD_CLK(),           // 1-bit input: FIFO read clock
      .FIFO_RD_EN(),            // 1-bit input: Enables reading the FIFO when asserted
      .RST(sync_rst)               // 1-bit input: Asynchronous Reset
   );

//detection bitslip
bitslip_detect bitslip_detect_inst (
    .clk_div(data_clk_div_internal),
    .data_in(frame_clk_data),
    .reset(sync_rst),
    .ena(enable),
    .bitslip_count(bitslip_count)
);

endmodule

module bitslip_detect (
    input wire          clk_div,
    input wire [7:0]    data_in,
    input wire          ena,
    input wire          reset,
    output reg [3:0]    bitslip_count
    );

reg [7:0] stage_one, stage_two;

always @ (posedge clk_div or posedge reset) begin
    if (reset) begin
        stage_one <= 8'd0;
        stage_two <= 8'd0;
        bitslip_count <= 4'd0;
    end
    else if (ena) begin
        stage_one <= data_in;
        stage_two <= stage_one;
        case (stage_two)
            8'b00001111: bitslip_count <= 4'd0;
            8'b00011110: bitslip_count <= 4'd1;
            8'b00111100: bitslip_count <= 4'd2;
            8'b01111000: bitslip_count <= 4'd3;
            8'b11110000: bitslip_count <= 4'd4;
            8'b11100001: bitslip_count <= 4'd5;
            8'b11000011: bitslip_count <= 4'd6;
            8'b10000111: bitslip_count <= 4'd7;
            default: bitslip_count <= 4'd15;
        endcase
    end
end
endmodule
