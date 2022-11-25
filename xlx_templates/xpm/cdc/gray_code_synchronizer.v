// XPM_CDC instantiation template for Synchronizer via Gray Encoding configurations
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
// | SIM_ASSERT_CHK       | Integer            | Allowed values: 0, 1. Default value = 0.                                |
// |---------------------------------------------------------------------------------------------------------------------|
// | 0- Disable simulation message reporting. Messages related to potential misuse will not be reported.                 |
// | 1- Enable simulation message reporting. Messages related to potential misuse will be reported.                      |
// +---------------------------------------------------------------------------------------------------------------------+
// | SIM_LOSSLESS_GRAY_CHK| Integer            | Allowed values: 0, 1. Default value = 0.                                |
// |---------------------------------------------------------------------------------------------------------------------|
// | 0- Disable simulation message that reports whether src_in_bin is incrementing or decrementing by one, guaranteeing  |
// | lossless synchronization of a gray coded bus.                                                                       |
// | 1- Enable simulation message that reports whether src_in_bin is incrementing or decrementing by one, guaranteeing   |
// | lossless synchronization of a gray coded bus.                                                                       |
// +---------------------------------------------------------------------------------------------------------------------+
// | WIDTH                | Integer            | Range: 2 - 32. Default value = 2.                                       |
// |---------------------------------------------------------------------------------------------------------------------|
// | Width of binary input bus that will be synchronized to destination clock domain.                                    |
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
// | dest_out_bin   | Output    | WIDTH                                 | dest_clk| NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | Binary input bus (src_in_bin) synchronized to destination clock domain. This output is combinatorial unless         |
// | REG_OUTPUT is set to 1.                                                                                             |
// +---------------------------------------------------------------------------------------------------------------------+
// | src_clk        | Input     | 1                                     | NA      | Rising edge | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | Source clock.                                                                                                       |
// +---------------------------------------------------------------------------------------------------------------------+
// | src_in_bin     | Input     | WIDTH                                 | src_clk | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | Binary input bus that will be synchronized to the destination clock domain.                                         |
// +---------------------------------------------------------------------------------------------------------------------+


// xpm_cdc_gray : In order to incorporate this function into the design,
//   Verilog    : the following instance declaration needs to be placed
//   instance   : in the body of the design code.  The instance name
// declaration  : (xpm_cdc_gray_inst) and/or the port declarations within the
//     code     : parenthesis may be changed to properly reference and
//              : connect this function to the design.  All inputs
//              : and outputs must be connected.

//  Please reference the appropriate libraries guide for additional information on the XPM modules.

//  <-----Cut code below this line---->

   // xpm_cdc_gray: Synchronizer via Gray Encoding
   // Xilinx Parameterized Macro, version 2019.1

   xpm_cdc_gray #(
      .DEST_SYNC_FF(4),          // DECIMAL; range: 2-10
      .INIT_SYNC_FF(0),          // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
      .REG_OUTPUT(0),            // DECIMAL; 0=disable registered output, 1=enable registered output
      .SIM_ASSERT_CHK(0),        // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .SIM_LOSSLESS_GRAY_CHK(0), // DECIMAL; 0=disable lossless check, 1=enable lossless check
      .WIDTH(2)                  // DECIMAL; range: 2-32
   )
   xpm_cdc_gray_inst (
      .dest_out_bin(dest_out_bin), // WIDTH-bit output: Binary input bus (src_in_bin) synchronized to
                                   // destination clock domain. This output is combinatorial unless REG_OUTPUT
                                   // is set to 1.

      .dest_clk(dest_clk),         // 1-bit input: Destination clock.
      .src_clk(src_clk),           // 1-bit input: Source clock.
      .src_in_bin(src_in_bin)      // WIDTH-bit input: Binary input bus that will be synchronized to the
                                   // destination clock domain.

   );

   // End of xpm_cdc_gray_inst instantiation
				

