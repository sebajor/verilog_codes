`default_nettype none
`include "mmcme4_base.v"


module mmcme4_base_tb #(
    parameter BANDWIDTH="OPTIMIZED",   // Jitter programming (OPTIMIZED, HIGH, LOW)
    parameter CLKFBOUT_MULT_F=5,     // Multiply value for all CLKOUT (2.000-64.000).
    parameter CLKFBOUT_PHASE=0.000, // Phase offset in degrees of CLKFB (-360.000-360.000).
    parameter DIVCLK_DIVIDE=1,         // Master division value (1-106)
    parameter CLKIN1_PERIOD=10,         // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
    
    parameter CLKOUT0_DIVIDE_F=1,    // Divide amount for CLKOUT0 (1.000-128.000).
    parameter CLKOUT0_PHASE=0.0,       // Phase offset for each CLKOUT (-360.000-360.000).
    parameter CLKOUT0_DUTY_CYCLE=0.5,

    parameter CLKOUT1_DIVIDE_F=1,    // Divide amount for CLKOUT0 (1.000-128.000).
    parameter CLKOUT1_PHASE=180.0,       // Phase offset for each CLKOUT (-360.000-360.000).
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


MMCME4_BASE #(
    .BANDWIDTH(BANDWIDTH),
    .CLKFBOUT_MULT_F(CLKFBOUT_MULT_F),
    .CLKFBOUT_PHASE(CLKFBOUT_PHASE),
    .DIVCLK_DIVIDE(DIVCLK_DIVIDE),
    .CLKIN1_PERIOD(CLKIN1_PERIOD),
    .CLKOUT0_DIVIDE_F(CLKOUT0_DIVIDE_F),
    .CLKOUT0_PHASE(CLKOUT0_PHASE),
    .CLKOUT0_DUTY_CYCLE(CLKOUT0_DUTY_CYCLE),
    .CLKOUT1_DIVIDE_F(CLKOUT1_DIVIDE_F),
    .CLKOUT1_PHASE(CLKOUT1_PHASE),
    .CLKOUT1_DUTY_CYCLE(CLKOUT1_DUTY_CYCLE),
    .CLKOUT2_DIVIDE_F(CLKOUT2_DIVIDE_F),
    .CLKOUT2_PHASE(CLKOUT2_PHASE),
    .CLKOUT2_DUTY_CYCLE(CLKOUT2_DUTY_CYCLE),
    .CLKOUT3_DIVIDE_F(CLKOUT3_DIVIDE_F),
    .CLKOUT3_PHASE(CLKOUT3_PHASE),
    .CLKOUT3_DUTY_CYCLE(CLKOUT3_DUTY_CYCLE),
    .CLKOUT4_DIVIDE_F(CLKOUT4_DIVIDE_F),
    .CLKOUT4_PHASE(CLKOUT4_PHASE),
    .CLKOUT4_DUTY_CYCLE(CLKOUT4_DUTY_CYCLE),
    .CLKOUT5_DIVIDE_F(CLKOUT5_DIVIDE_F),
    .CLKOUT5_PHASE(CLKOUT5_PHASE),
    .CLKOUT5_DUTY_CYCLE(CLKOUT5_DUTY_CYCLE),
    .CLKOUT6_DIVIDE_F(CLKOUT6_DIVIDE_F),
    .CLKOUT6_PHASE(CLKOUT6_PHASE),
    .CLKOUT6_DUTY_CYCLE(CLKOUT6_DUTY_CYCLE),
    .REF_JITTER1(REF_JITTER1),
    .STARTUP_WAIT(STARTUP_WAIT)
) mmcme4_base_inst  (
    .CLKFBIN(CLKFBIN),
    .CLKFBOUT(CLKFBOUT),
    .CLKFBOUTB(CLKFBOUTB),
    .CLKIN1(CLKIN1),
    .RST(RST),
    .CLKOUT0(CLKOUT0),
    .CLKOUT0B(CLKOUT0B),
    .CLKOUT1(CLKOUT1),
    .CLKOUT1B(CLKOUT1B),
    .CLKOUT2(CLKOUT2),
    .CLKOUT2B(CLKOUT2B),
    .CLKOUT3(CLKOUT3),
    .CLKOUT3B(CLKOUT3B),
    .CLKOUT4(CLKOUT4),
    .CLKOUT5(CLKOUT5),
    .CLKOUT6(CLKOUT6),
    .LOCKED(LOCKED)
);

endmodule
