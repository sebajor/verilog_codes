
// XPM_CDC instantiation template for Synchronous Reset Synchronizer configurations
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
// | INIT                 | Integer            | Allowed values: 1, 0. Default value = 1.                                |
// |---------------------------------------------------------------------------------------------------------------------|
// | 0- Initializes synchronization registers to 0                                                                       |
// | 1- Initializes synchronization registers to 1                                                                       |
// | The option to initialize the synchronization registers means that there is no complete x-propagation behavior       |
// | modeled in this macro. For complete x-propagation modelling, use the xpm_cdc_single macro.                          |
// +---------------------------------------------------------------------------------------------------------------------+
// | INIT_SYNC_FF         | Integer            | Allowed values: 0, 1. Default value = 0.                                |
// |---------------------------------------------------------------------------------------------------------------------|
// | 0- Disable behavioral simulation initialization value(s) on synchronization registers.                              |
// | 1- Enable behavioral simulation initialization value(s) on synchronization registers.                               |
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
// | dest_rst       | Output    | 1                                     | dest_clk| NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | src_rst synchronized to the destination clock domain. This output is registered.                                    |
// +---------------------------------------------------------------------------------------------------------------------+
// | src_rst        | Input     | 1                                     | NA      | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | Source reset signal.                                                                                                |
// +---------------------------------------------------------------------------------------------------------------------+


// xpm_cdc_sync_rst : In order to incorporate this function into the design,
//     Verilog      : the following instance declaration needs to be placed
//     instance     : in the body of the design code.  The instance name
//   declaration    : (xpm_cdc_sync_rst_inst) and/or the port declarations within the
//       code       : parenthesis may be changed to properly reference and
//                  : connect this function to the design.  All inputs
//                  : and outputs must be connected.

//  Please reference the appropriate libraries guide for additional information on the XPM modules.

//  <-----Cut code below this line---->

   // xpm_cdc_sync_rst: Synchronous Reset Synchronizer
   // Xilinx Parameterized Macro, version 2019.1

   xpm_cdc_sync_rst #(
      .DEST_SYNC_FF(4),   // DECIMAL; range: 2-10
      .INIT(1),           // DECIMAL; 0=initialize synchronization registers to 0, 1=initialize synchronization
                          // registers to 1
      .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
      .SIM_ASSERT_CHK(0)  // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
   )
   xpm_cdc_sync_rst_inst (
      .dest_rst(dest_rst), // 1-bit output: src_rst synchronized to the destination clock domain. This output
                           // is registered.

      .dest_clk(dest_clk), // 1-bit input: Destination clock.
      .src_rst(src_rst)    // 1-bit input: Source reset signal.
   );

   // End of xpm_cdc_sync_rst_inst instantiation
				
	
