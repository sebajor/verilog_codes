`default_nettype none

//dumbs simulations

module IBUFDS #(
    parameter IOSTANDARD = "LVDS_25",
    parameter DIFF_TERM = "TRUE"
) (
    input wire I,
    input wire IB,
    output wire O
);

    assign O = I;


endmodule

module BUFR #(
    parameter BUFR_DIVIDE = 4
) (
    input wire I,
    input wire CE,
    input wire CLR,
    output wire O
);

endmodule


module BUFIO (
    input wire I,
    input wire O
);
    assign O = I;
endmodule



module IDELAYE2 #(
    parameter IDELAY_TYPE ="FIXED",
    parameter DELAY_SRC ="IDATAIN",
    parameter IDELAY_VALUE =14, // a value of 14 should give ~1.1ns with a 200MHz reference
    parameter HIGH_PERFORMANCE_MODE ="TRUE",
    parameter SIGNAL_PATTERN ="DATA",
    parameter REFCLK_FREQUENCY =200,
    parameter CINVCTRL_SEL ="FALSE",
    parameter PIPE_SEL ="FALSE"
) (
    input wire C,
    input wire REGRST,
    input wire LD,
    input wire CE,
    input wire INC,
    input wire CINVCTRL,
    input wire [8:0] CNTVALUEIN,
    input wire IDATAIN,
    input wire DATAIN,
    input wire LDPIPEEN,
    output wire DATAOUT,
    output wire [4:0] CNTVALUEOUT
);


endmodule


module ISERDESE2 #(
    parameter DATA_RATE = "DDR",
    parameter DATA_WIDTH = 8,
    parameter INTERFACE_TYPE = "NETWORKING", // Using internal clock network routing
    parameter DYN_CLKDIV_INV_EN = "FALSE", // We do not need dynamic clocking
    parameter DYN_CLK_INV_EN = "FALSE", // We do not need dynamic clocking
    parameter NUM_CE = 1, // Only use CE1 as a clock enable
    parameter OFB_USED = "FALSE", //
    parameter IOBDELAY = "BOTH",
    parameter SERDES_MODE = "MASTER"
) (
    output wire Q1,
    output wire Q2,
    output wire Q3,
    output wire Q4,
    output wire Q5,
    output wire Q6,
    output wire Q7,
    output wire Q8,
    output wire O,
    output wire SHIFTOUT1,
    output wire SHIFTOUT2,
    input wire D,
    input wire DDLY,
    input wire CLK,
    input wire CLKB,
    input wire CE1,
    input wire CE2,
    input wire RST,
    input wire CLKDIV,
    input wire CLKDIVP,
    input wire OCLK,
    input wire OCLKB,
    input wire BITSLIP,
    input wire SHIFTIN1,
    input wire SHIFTIN2,
    input wire OFB,
    input wire DYNCLKDIVSEL,
    input wire DYNCLKSEL
);

endmodule


module ODDR #(
	parameter DDR_CLK_EDGE = "OPPOSITE_EDGE",
	parameter INIT  = 1'b0,
	parameter SRTYPE = "SYNC"
) (
    output wire Q,
	input wire C,
	input wire CE,
	input wire D1,
	input wire D2,
	input wire R,
	input wire S
);



endmodule

module OBUFDS (
	input wire I,
	output wire O,
	output wire OB
);

    assign O = I;
    assign OB = ~I;

endmodule

module IDELAYCTRL (
	input wire RST,
	input wire REFCLK,
	output wire RDY
);



endmodule


//ultrascale

module MMCME4_BASE #(
    parameter BANDWIDTH="OPTIMIZED",   // Jitter programming (OPTIMIZED, HIGH, LOW)
    parameter CLKFBOUT_MULT_F=5,     // Multiply value for all CLKOUT (2.000-64.000).
    parameter CLKFBOUT_PHASE=0.000, // Phase offset in degrees of CLKFB (-360.000-360.000).
    parameter DIVCLK_DIVIDE=1,         // Master division value (1-106)
    parameter CLKIN1_PERIOD=0,         // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
    parameter CLKOUT0_DIVIDE_F=1,    // Divide amount for CLKOUT0 (1.000-128.000).
    parameter CLKOUT0_PHASE=0.0,       // Phase offset for each CLKOUT (-360.000-360.000).
    parameter CLKOUT0_DUTY_CYCLE=0.5,

    parameter CLKOUT1_DIVIDE_F=1,    // Divide amount for CLKOUT0 (1.000-128.000).
    parameter CLKOUT1_PHASE=0.0,       // Phase offset for each CLKOUT (-360.000-360.000).
    parameter CLKOUT1_DUTY_CYCLE=0.5,

    parameter CLKOUT2_DIVIDE_F=1,    // Divide amount for CLKOUT0 (1.000-128.000).
    parameter CLKOUT2_PHASE=0.0,       // Phase offset for each CLKOUT (-360.000-360.000).
    parameter CLKOUT2_DUTY_CYCLE=0.5,

    parameter CLKOUT3_DIVIDE_F=1,    // Divide amount for CLKOUT0 (1.000-128.000).
    parameter CLKOUT3_PHASE=0.0,       // Phase offset for each CLKOUT (-360.000-360.000).
    parameter CLKOUT3_DUTY_CYCLE=0.5,

    parameter CLKOUT4_DIVIDE_F=1,    // Divide amount for CLKOUT0 (1.000-128.000).
    parameter CLKOUT4_PHASE=0.0,       // Phase offset for each CLKOUT (-360.000-360.000).
    parameter CLKOUT4_DUTY_CYCLE=0.5,

    parameter CLKOUT5_DIVIDE_F=1,    // Divide amount for CLKOUT0 (1.000-128.000).
    parameter CLKOUT5_PHASE=0.0,       // Phase offset for each CLKOUT (-360.000-360.000).
    parameter CLKOUT5_DUTY_CYCLE=0.5,

    parameter CLKOUT6_DIVIDE_F=1,    // Divide amount for CLKOUT0 (1.000-128.000).
    parameter CLKOUT6_PHASE=0.0,       // Phase offset for each CLKOUT (-360.000-360.000).
    parameter CLKOUT6_DUTY_CYCLE=0.5,

    parameter REF_JITTER1=0.0,         // Reference input jitter in UI (0.000-0.999).
    parameter STARTUP_WAIT="FALSE"     // Delays DONE until MMCM is locked (FALSE, TRUE)
        ) (
    input wire CLKFBIN, // 1-bit input: Feedback clock
    output wire CLKFBOUT,    // 1-bit output: Feedback clock
    output wire CLKFBOUTB,    // 1-bit output: Feedback clock

    input wire CLKIN1,      // 1-bit input: Clock
    input wire RST,                // 1-bit input: Reset


    output wire CLKOUT0,   // 1-bit output: CLKOUT0
    output wire CLKOUT0B,   //inverted CLKOUT0

    output wire CLKOUT1,   // 1-bit output: CLKOUT
    output wire CLKOUT1B,   //inverted CLKOUT
    
    output wire CLKOUT2,   // 1-bit output: CLKOUT
    output wire CLKOUT2B,   //inverted CLKOUT

    output wire CLKOUT3,   // 1-bit output: CLKOUT
    output wire CLKOUT3B,   //inverted CLKOUT


    output wire CLKOUT4,   // 1-bit output: CLKOUT
    output wire CLKOUT5,   // 1-bit output: CLKOUT
    output wire CLKOUT6,   // 1-bit output: CLKOUT

    output wire LOCKED                 // 1-bit output: LOCK
        );

    assign CLKOUT0B = ~CLKOUT0;
    assign CLKOUT1B = ~CLKOUT1;
    assign CLKOUT2B = ~CLKOUT2;
    assign CLKOUT3B = ~CLKOUT3;


endmodule



module BUFG (
    input wire I,
    output wire O
);
    assign O = I;

endmodule

module ISERDESE3 #(
        parameter DATA_WIDTH=8,// Parallel data width (4,8)
        parameter FIFO_ENABLE="FALSE",// Enables the use of the FIFO
        parameter FIFO_SYNC_MODE="FALSE",// Always set to FALSE. TRUE is reserved for later use.
        parameter IS_CLK_B_INVERTED=1'b1,// Optional inversion for CLK_B
        parameter IS_CLK_INVERTED=1'b0,// Optional inversion for CLK
        parameter IS_RST_INVERTED=1'b0,// Optional inversion for RST
        parameter SIM_DEVICE="ULTRASCALE_PLUS"  // Set the device version for simulation functionality (ULTRASCALE,
   )(
        output wire FIFO_EMPTY,            // 1-bit output: FIFO empty flag
        output wire INTERNAL_DIVCLK,       // 1-bit output: Internally divided down clock used when FIFO is
        output wire [DATA_WIDTH-1:0] Q,         // 8-bit registered output
        input wire CLK,      // 1-bit input: High-speed clock
        input wire CLKDIV,        // 1-bit input: Divided Clock
        input wire CLK_B,    // 1-bit input: Inversion of High-speed clock CLK
        input wire D,          // 1-bit input: Serial Data Input
        input wire FIFO_RD_CLK,           // 1-bit input: FIFO read clock
        input wire FIFO_RD_EN,            // 1-bit input: Enables reading the FIFO when asserted
        input wire RST               // 1-bit input: Asynchronous Reset
   );

reg [$clog2(DATA_WIDTH)-1:0] counter =0;
reg [DATA_WIDTH-1:0] internal_reg=0;
generate
    if(DATA_WIDTH==4)begin
        //SDR mode
        always@(posedge CLK)begin
            internal_reg[counter] <= D;
            if(counter==(DATA_WIDTH-1))
                counter <= 0;
            else 
                counter <= counter+1;
        end
    end
    else begin
        //DDR mode
        always@(posedge CLK or negedge CLK)begin
            internal_reg[counter] <= D;
            if(counter==(DATA_WIDTH-1))
                counter <= 0;
            else 
                counter <= counter+1;
        end
    end
endgenerate



assign Q = internal_reg;

endmodule
