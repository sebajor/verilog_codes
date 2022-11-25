// XPM_CDC instantiation template for Bus Synchronizer with Full Handshake configurations
// Refer to the targeted device family architecture libraries guide for XPM_CDC documentation
// =======================================================================================================================

// Parameter usage table, organized as follows:
// +---------------------------------------------------------------------------------------------------------------------+
// | Parameter name       | Data type          | Restrictions, if applicable                                             |
// |---------------------------------------------------------------------------------------------------------------------|
// | Description                                                                                                         |
// +---------------------------------------------------------------------------------------------------------------------+
// +---------------------------------------------------------------------------------------------------------------------+
// | DEST_EXT_HSK         | Integer            | Allowed values: 1, 0. Default value = 1.                                |
// |---------------------------------------------------------------------------------------------------------------------|
// | 0- An internal handshake will be implemented in the macro to acknowledge receipt of data on the destination clock   |
// | domain. When using this option, the valid dest_out output must be consumed immediately to avoid any data loss.      |
// | 1- External handshake logic must be implemented by the user to acknowledge receipt of data on the destination clock |
// | domain.                                                                                                             |
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
// | SIM_ASSERT_CHK       | Integer            | Allowed values: 0, 1. Default value = 0.                                |
// |---------------------------------------------------------------------------------------------------------------------|
// | 0- Disable simulation message reporting. Messages related to potential misuse will not be reported.                 |
// | 1- Enable simulation message reporting. Messages related to potential misuse will be reported.                      |
// +---------------------------------------------------------------------------------------------------------------------+
// | SRC_SYNC_FF          | Integer            | Range: 2 - 10. Default value = 4.                                       |
// |---------------------------------------------------------------------------------------------------------------------|
// | Number of register stages used to synchronize signal in the source clock domain.                                    |
// +---------------------------------------------------------------------------------------------------------------------+
// | WIDTH                | Integer            | Range: 1 - 1024. Default value = 1.                                     |
// |---------------------------------------------------------------------------------------------------------------------|
// | Width of bus that will be synchronized to destination clock domain.                                                 |
// +---------------------------------------------------------------------------------------------------------------------+

// Port usage table, organized as follows:
// +---------------------------------------------------------------------------------------------------------------------+
// | Port name      | Direction | Size, in bits                         | Domain  | Sense       | Handling if unused     |
// |---------------------------------------------------------------------------------------------------------------------|
// | Description                                                                                                         |
// +---------------------------------------------------------------------------------------------------------------------+
// +---------------------------------------------------------------------------------------------------------------------+
// | dest_ack       | Input     | 1                                     | dest_clk| Active-high | Tie to 1'b0            |
// |---------------------------------------------------------------------------------------------------------------------|
// | Destination logic acknowledgement if DEST_EXT_HSK = 1. Unused when DEST_EXT_HSK = 0.                                |
// | Asserting this signal indicates that data on dest_out has been captured by the destination logic.                   |
// | This signal should be deasserted once dest_req is deasserted, completing the handshake on the destination clock     |
// | domain and indicating that the destination logic is ready for a new data transfer.                                  |
// +---------------------------------------------------------------------------------------------------------------------+
// | dest_clk       | Input     | 1                                     | NA      | Rising edge | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | Destination clock.                                                                                                  |
// +---------------------------------------------------------------------------------------------------------------------+
// | dest_out       | Output    | WIDTH                                 | dest_clk| NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | Input bus (src_in) synchronized to destination clock domain. This output is registered.                             |
// +---------------------------------------------------------------------------------------------------------------------+
// | dest_req       | Output    | 1                                     | dest_clk| Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | Assertion of this signal indicates that new dest_out data has been received and is ready to be used or captured     |
// | by the destination logic.                                                                                           |
// |                                                                                                                     |
// |   When DEST_EXT_HSK = 1, this signal will deassert once the source handshake acknowledges that the destination clock|
// | domain has received the transferred data.                                                                           |
// |   When DEST_EXT_HSK = 0, this signal asserts for one clock period when dest_out bus is valid.                       |
// |                                                                                                                     |
// | This output is registered.                                                                                          |
// +---------------------------------------------------------------------------------------------------------------------+
// | src_clk        | Input     | 1                                     | NA      | Rising edge | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | Source clock.                                                                                                       |
// +---------------------------------------------------------------------------------------------------------------------+
// | src_in         | Input     | WIDTH                                 | src_clk | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | Input bus that will be synchronized to the destination clock domain.                                                |
// +---------------------------------------------------------------------------------------------------------------------+
// | src_rcv        | Output    | 1                                     | src_clk | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | Acknowledgement from destination logic that src_in has been received.                                               |
// | This signal will be deasserted once destination handshake has fully completed, thus completing a full               |
// | data transfer. This output is registered.                                                                           |
// +---------------------------------------------------------------------------------------------------------------------+
// | src_send       | Input     | 1                                     | src_clk | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | Assertion of this signal allows the src_in bus to be synchronized to the destination clock domain.                  |
// |                                                                                                                     |
// |   This signal should only be asserted when src_rcv is deasserted, indicating that the previous data transfer        |
// | is complete.                                                                                                        |
// |   This signal should only be deasserted once src_rcv is asserted, acknowledging that the src_in has been received by|
// | the destination logic.                                                                                              |
// +---------------------------------------------------------------------------------------------------------------------+


// xpm_cdc_handshake : In order to incorporate this function into the design,
//      Verilog      : the following instance declaration needs to be placed
//     instance      : in the body of the design code.  The instance name
//    declaration    : (xpm_cdc_handshake_inst) and/or the port declarations within the
//       code        : parenthesis may be changed to properly reference and
//                   : connect this function to the design.  All inputs
//                   : and outputs must be connected.

//  Please reference the appropriate libraries guide for additional information on the XPM modules.

//  <-----Cut code below this line---->

   // xpm_cdc_handshake: Bus Synchronizer with Full Handshake
   // Xilinx Parameterized Macro, version 2019.1

   xpm_cdc_handshake #(
      .DEST_EXT_HSK(1),   // DECIMAL; 0=internal handshake, 1=external handshake
      .DEST_SYNC_FF(4),   // DECIMAL; range: 2-10
      .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
      .SIM_ASSERT_CHK(0), // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .SRC_SYNC_FF(4),    // DECIMAL; range: 2-10
      .WIDTH(1)           // DECIMAL; range: 1-1024
   )
   xpm_cdc_handshake_inst (
      .dest_out(dest_out), // WIDTH-bit output: Input bus (src_in) synchronized to destination clock domain.
                           // This output is registered.

      .dest_req(dest_req), // 1-bit output: Assertion of this signal indicates that new dest_out data has been
                           // received and is ready to be used or captured by the destination logic. When
                           // DEST_EXT_HSK = 1, this signal will deassert once the source handshake
                           // acknowledges that the destination clock domain has received the transferred data.
                           // When DEST_EXT_HSK = 0, this signal asserts for one clock period when dest_out bus
                           // is valid. This output is registered.

      .src_rcv(src_rcv),   // 1-bit output: Acknowledgement from destination logic that src_in has been
                           // received. This signal will be deasserted once destination handshake has fully
                           // completed, thus completing a full data transfer. This output is registered.

      .dest_ack(dest_ack), // 1-bit input: optional; required when DEST_EXT_HSK = 1
      .dest_clk(dest_clk), // 1-bit input: Destination clock.
      .src_clk(src_clk),   // 1-bit input: Source clock.
      .src_in(src_in),     // WIDTH-bit input: Input bus that will be synchronized to the destination clock
                           // domain.

      .src_send(src_send)  // 1-bit input: Assertion of this signal allows the src_in bus to be synchronized to
                           // the destination clock domain. This signal should only be asserted when src_rcv is
                           // deasserted, indicating that the previous data transfer is complete. This signal
                           // should only be deasserted once src_rcv is asserted, acknowledging that the src_in
                           // has been received by the destination logic.

   );

   // End of xpm_cdc_handshake_inst instantiation
				

