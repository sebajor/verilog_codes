`default_nettype none

/*
Example of one pll which receive as input 100mhz clk and generate two 200mhz
clock with 180 with oposite phases and one 100mhz clock
*/

module pll_ex(
    input wire clk_100mhz,
    output wire clk_200_p,
    output wire clk_200_n,
    output wire clk_100_pll
);

wire clk_100mhz_ibufg;
IBUFG clk_ibufg_inst(
    .I(clk_100mhz),
    .O(clk_100mhz_ibufg)
);
   
wire clk_200mhz_p, clk_200mhz_n;
wire clk_100mhz_pll;
wire pll_clkfb;
wire pll_locked;
wire pll_rst = 1'b0;

/*counter divider D = 1
    fractional divide M = 8
    kintex vco range: (600-1440) mhz
    fvco = fin*M/D; fout=fin*M/(D*O)
    fin=100mhz, M=8, D=1 -> fvco=800
    O = 4 for clk1 and clk2
    O = 8 for clk3
*/
PLLE2_BASE #(
    .BANDWIDTH("OPTIMIZED"),  // OPTIMIZED, HIGH, LOW
    .CLKFBOUT_MULT(8),        // M (2-64)
    .DIVCLK_DIVIDE(1),        // D (1-56)
    .CLKFBOUT_PHASE(0.0),     // Phase offset in degrees of CLKFB, (-360.000-360.000).
    .CLKIN1_PERIOD(10.0),     // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
    .REF_JITTER1(0.0),        // Reference input jitter in UI, (0.000-0.999).
    .STARTUP_WAIT("FALSE"),   // Delay DONE until PLL Locks, ("TRUE"/"FALSE")
            
    .CLKOUT0_DIVIDE(4),
    .CLKOUT0_DUTY_CYCLE(0.5),
    .CLKOUT0_PHASE(0.0),

    .CLKOUT1_DIVIDE(4),
    .CLKOUT1_DUTY_CYCLE(0.5),
    .CLKOUT1_PHASE(180.0),

    .CLKOUT2_DIVIDE(8),
    .CLKOUT2_DUTY_CYCLE(0.5),
    .CLKOUT2_PHASE(0.0),

    .CLKOUT3_DIVIDE(1),
    .CLKOUT3_DUTY_CYCLE(0.5),
    .CLKOUT3_PHASE(0.0),

    .CLKOUT4_DIVIDE(1),
    .CLKOUT4_DUTY_CYCLE(0.5),
    .CLKOUT4_PHASE(0.0),

    .CLKOUT5_DIVIDE(1),
    .CLKOUT5_DUTY_CYCLE(0.5),
    .CLKOUT5_PHASE(0.0)
) PLLE2_BASE_inst (
    .PWRDWN(1'b0),
    .RST(pll_rst),      
    .LOCKED(pll_locked),
    .CLKFBIN(pll_clkfb),    //Feedback clock
    .CLKFBOUT(pll_clkfb),   //Feedback clock
    .CLKIN1(clk_100mhz_ibufg),    
    .CLKOUT0(clk_200mhz_p),
    .CLKOUT1(clk_200mhz_n),
    .CLKOUT2(clk_100mhz_pll),
    .CLKOUT3(),
    .CLKOUT4(),
    .CLKOUT5()
); 

assign clk_200_p = clk_200mhz_p;
assign clk_200_n = clk_200mhz_n;
assign clk_100_pll = clk_100mhz_pll;

endmodule 

