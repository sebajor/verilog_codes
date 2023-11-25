`default_nettype none

module MMCME4_BASE #(
    parameter BANDWIDTH="OPTIMIZED",   // Jitter programming (OPTIMIZED, HIGH, LOW)
    parameter CLKFBOUT_MULT_F=5,     // Multiply value for all CLKOUT (2.000-64.000).
    parameter CLKFBOUT_PHASE=0.000, // Phase offset in degrees of CLKFB (-360.000-360.000).
    parameter DIVCLK_DIVIDE=1,         // Master division value (1-106)
    parameter CLKIN1_PERIOD=0,         // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
    parameter CLKOUT0_DIVIDE_F=1,    // Divide amount for CLKOUT0 (1.000-128.000).
    parameter CLKOUT0_PHASE=0.0,       // Phase offset for each CLKOUT (-360.000-360.000).
    parameter CLKOUT0_DUTY_CYCLE=0.5,

    parameter CLKOUT1_DIVIDE=1,    // Divide amount for CLKOUT0 (1.000-128.000).
    parameter CLKOUT1_PHASE=0.0,       // Phase offset for each CLKOUT (-360.000-360.000).
    parameter CLKOUT1_DUTY_CYCLE=0.5,

    parameter CLKOUT2_DIVIDE=1,    // Divide amount for CLKOUT0 (1.000-128.000).
    parameter CLKOUT2_PHASE=0.0,       // Phase offset for each CLKOUT (-360.000-360.000).
    parameter CLKOUT2_DUTY_CYCLE=0.5,

    parameter CLKOUT3_DIVIDE=1,    // Divide amount for CLKOUT0 (1.000-128.000).
    parameter CLKOUT3_PHASE=0.0,       // Phase offset for each CLKOUT (-360.000-360.000).
    parameter CLKOUT3_DUTY_CYCLE=0.5,

    parameter CLKOUT4_DIVIDE=1,    // Divide amount for CLKOUT0 (1.000-128.000).
    parameter CLKOUT4_PHASE=0.0,       // Phase offset for each CLKOUT (-360.000-360.000).
    parameter CLKOUT4_DUTY_CYCLE=0.5,

    parameter CLKOUT5_DIVIDE=1,    // Divide amount for CLKOUT0 (1.000-128.000).
    parameter CLKOUT5_PHASE=0.0,       // Phase offset for each CLKOUT (-360.000-360.000).
    parameter CLKOUT5_DUTY_CYCLE=0.5,

    parameter CLKOUT6_DIVIDE=1,    // Divide amount for CLKOUT0 (1.000-128.000).
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

