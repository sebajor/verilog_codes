// XPM_CDC instantiation template for Pulse Transfer configurations
// Refer to the targeted device family architecture libraries guide for XPM_CDC documentation
// =======================================================================================================================

// Parameter usage table, organized as follows:
// +---------------------------------------------------------------------------------------------------------------------+
// | Parameter name       | Data type          | Restrictions, if applicable                                             |
// |---------------------------------------------------------------------------------------------------------------------|
// | Description                                                                                                         |
// +---------------------------------------------------------------------------------------------------------------------+
// +---------------------------------------------------------------------------------------------------------------------+
// | DEST_SYNC_FF         | Integer            | Range: 2 - 10. Default value = 4.                                       |
// |---------------------------------------------------------------------------------------------------------------------|
// | Number of register stages used to synchronize signal in the destination clock domain.                               |
// +---------------------------------------------------------------------------------------------------------------------+
// | INIT_SYNC_FF         | Integer            | Allowed values: 0, 1. Default value = 0.                                |
// |---------------------------------------------------------------------------------------------------------------------|
// | 0- Disable behavioral simulation initialization value(s) on synchronization registers.                              |
// | 1- Enable behavioral simulation initialization value(s) on synchronization registers.                               |
// +---------------------------------------------------------------------------------------------------------------------+
// | REG_OUTPUT           | Integer            | Allowed values: 0, 1. Default value = 0.                                |
// |---------------------------------------------------------------------------------------------------------------------|
// | 0- Disable registered output                                                                                        |
// | 1- Enable registered output                                                                                         |
// +---------------------------------------------------------------------------------------------------------------------+
// | RST_USED             | Integer            | Allowed values: 1, 0. Default value = 1.                                |
// |---------------------------------------------------------------------------------------------------------------------|
// | 0 - No resets implemented.                                                                                          |
// | 1 - Resets implemented.                                                                                             |
// | When RST_USED = 0, src_pulse input must always be defined during simulation since there is no reset logic to        |
// | recover from an x-propagating through the macro.                                                                    |
// +---------------------------------------------------------------------------------------------------------------------+
// | SIM_ASSERT_CHK       | Integer            | Allowed values: 0, 1. Default value = 0.                                |
// |---------------------------------------------------------------------------------------------------------------------|
// | 0- Disable simulation message reporting. Messages related to potential misuse will not be reported.                 |
// | 1- Enable simulation message reporting. Messages related to potential misuse will be reported.                      |
// +---------------------------------------------------------------------------------------------------------------------+

// Port usage table, organized as follows:
// +---------------------------------------------------------------------------------------------------------------------+
// | Port name      | Direction | Size, in bits                         | Domain  | Sense       | Handling if unused     |
// |---------------------------------------------------------------------------------------------------------------------|
// | Description                                                                                                         |
// +---------------------------------------------------------------------------------------------------------------------+
// +---------------------------------------------------------------------------------------------------------------------+
// | dest_clk       | Input     | 1                                     | NA      | Rising edge | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | Destination clock.                                                                                                  |
// +---------------------------------------------------------------------------------------------------------------------+
// | dest_pulse     | Output    | 1                                     | dest_clk| Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | Outputs a pulse the size of one dest_clk period when a pulse transfer is correctly initiated on src_pulse input.    |
// | This output is combinatorial unless REG_OUTPUT is set to 1.                                                         |
// +---------------------------------------------------------------------------------------------------------------------+
// | dest_rst       | Input     | 1                                     | dest_clk| Active-high | Tie to 1'b0            |
// |---------------------------------------------------------------------------------------------------------------------|
// | Unused when RST_USED = 0. Destination reset signal if RST_USED = 1.                                                 |
// | Resets all logic in destination clock domain.                                                                       |
// | To fully reset the macro, src_rst and dest_rst must be asserted simultaneously for at least                         |
// | ((DEST_SYNC_FF+2)*dest_clk_period) + (2*src_clk_period).                                                            |
// +---------------------------------------------------------------------------------------------------------------------+
// | src_clk        | Input     | 1                                     | NA      | Rising edge | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | Source clock.                                                                                                       |
// +---------------------------------------------------------------------------------------------------------------------+
// | src_pulse      | Input     | 1                                     | src_clk | Rising edge | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | Rising edge of this signal initiates a pulse transfer to the destination clock domain.                              |
// | The minimum gap between each pulse transfer must be at the minimum 2*(larger(src_clk period, dest_clk period)).     |
// | This is measured between the falling edge of a src_pulse to the rising edge of the next src_pulse. This minimum     |
// | gap will guarantee that each rising edge of src_pulse will generate a pulse the size of one dest_clk period in the  |
// | destination clock domain.                                                                                           |
// | When RST_USED = 1, pulse transfers will not be guaranteed while src_rst and/or dest_rst are asserted.               |
// +---------------------------------------------------------------------------------------------------------------------+
// | src_rst        | Input     | 1                                     | src_clk | Active-high | Tie to 1'b0            |
// |---------------------------------------------------------------------------------------------------------------------|
// | Unused when RST_USED = 0. Source reset signal if RST_USED = 1.                                                      |
// | Resets all logic in source clock domain.                                                                            |
// | To fully reset the macro, src_rst and dest_rst must be asserted simultaneously for at least                         |
// | ((DEST_SYNC_FF+2)*dest_clk_period) + (2*src_clk_period).                                                            |
// +---------------------------------------------------------------------------------------------------------------------+


// xpm_cdc_pulse : In order to incorporate this function into the design,
//    Verilog    : the following instance declaration needs to be placed
//   instance    : in the body of the design code.  The instance name
//  declaration  : (xpm_cdc_pulse_inst) and/or the port declarations within the
//     code      : parenthesis may be changed to properly reference and
//               : connect this function to the design.  All inputs
//               : and outputs must be connected.

//  Please reference the appropriate libraries guide for additional information on the XPM modules.

//  <-----Cut code below this line---->

   // xpm_cdc_pulse: Pulse Transfer
   // Xilinx Parameterized Macro, version 2019.1

   xpm_cdc_pulse #(
      .DEST_SYNC_FF(4),   // DECIMAL; range: 2-10
      .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
      .REG_OUTPUT(0),     // DECIMAL; 0=disable registered output, 1=enable registered output
      .RST_USED(1),       // DECIMAL; 0=no reset, 1=implement reset
      .SIM_ASSERT_CHK(0)  // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
   )
   xpm_cdc_pulse_inst (
      .dest_pulse(dest_pulse), // 1-bit output: Outputs a pulse the size of one dest_clk period when a pulse
                               // transfer is correctly initiated on src_pulse input. This output is
                               // combinatorial unless REG_OUTPUT is set to 1.

      .dest_clk(dest_clk),     // 1-bit input: Destination clock.
      .dest_rst(dest_rst),     // 1-bit input: optional; required when RST_USED = 1
      .src_clk(src_clk),       // 1-bit input: Source clock.
      .src_pulse(src_pulse),   // 1-bit input: Rising edge of this signal initiates a pulse transfer to the
                               // destination clock domain. The minimum gap between each pulse transfer must be
                               // at the minimum 2*(larger(src_clk period, dest_clk period)). This is measured
                               // between the falling edge of a src_pulse to the rising edge of the next
                               // src_pulse. This minimum gap will guarantee that each rising edge of src_pulse
                               // will generate a pulse the size of one dest_clk period in the destination
                               // clock domain. When RST_USED = 1, pulse transfers will not be guaranteed while
                               // src_rst and/or dest_rst are asserted.

      .src_rst(src_rst)        // 1-bit input: optional; required when RST_USED = 1
   );

   // End of xpm_cdc_pulse_inst instantiation
				

