// XPM_FIFO instantiation template for AXI Memory Mapped FIFO configurations
// Refer to the targeted device family architecture libraries guide for XPM_FIFO documentation
// =======================================================================================================================

// Parameter usage table, organized as follows:
// +---------------------------------------------------------------------------------------------------------------------+
// | Parameter name       | Data type          | Restrictions, if applicable                                             |
// |---------------------------------------------------------------------------------------------------------------------|
// | Description                                                                                                         |
// +---------------------------------------------------------------------------------------------------------------------+
// +---------------------------------------------------------------------------------------------------------------------+
// | AXI_ADDR_WIDTH       | Integer            | Range: 1 - 64. Default value = 32.                                      |
// |---------------------------------------------------------------------------------------------------------------------|
// | Defines the width of the ADDR ports, s_axi_araddr, s_axi_awaddr, m_axi_araddr and m_axi_awaddr                      |
// +---------------------------------------------------------------------------------------------------------------------+
// | AXI_DATA_WIDTH       | Integer            | Range: 8 - 1024. Default value = 32.                                    |
// |---------------------------------------------------------------------------------------------------------------------|
// | Defines the width of the DATA ports, s_axi_rdata, s_axi_wdata, m_axi_rdata and m_axi_wdata                          |
// | NOTE: The maximum FIFO size (width x depth) is limited to 150-Megabits.                                             |
// +---------------------------------------------------------------------------------------------------------------------+
// | CDC_SYNC_STAGES      | Integer            | Range: 2 - 8. Default value = 2.                                        |
// |---------------------------------------------------------------------------------------------------------------------|
// | Specifies the number of synchronization stages on the CDC path.                                                     |
// | Applicable only if CLOCKING_MODE = "independent_clock"                                                              |
// +---------------------------------------------------------------------------------------------------------------------+
// | CLOCKING_MODE        | String             | Allowed values: common_clock, independent_clock. Default value = common_clock.|
// |---------------------------------------------------------------------------------------------------------------------|
// | Designate whether AXI Memory Mapped FIFO is clocked with a common clock or with independent clocks-                 |
// |                                                                                                                     |
// |   "common_clock"- Common clocking; clock both write and read domain s_aclk                                          |
// |   "independent_clock"- Independent clocking; clock write domain with s_aclk and read domain with m_aclk             |
// +---------------------------------------------------------------------------------------------------------------------+
// | ECC_MODE_RDCH        | String             | Allowed values: no_ecc, en_ecc. Default value = no_ecc.                 |
// |---------------------------------------------------------------------------------------------------------------------|
// |                                                                                                                     |
// |   "no_ecc" - Disables ECC                                                                                           |
// |   "en_ecc" - Enables both ECC Encoder and Decoder                                                                   |
// +---------------------------------------------------------------------------------------------------------------------+
// | ECC_MODE_WDCH        | String             | Allowed values: no_ecc, en_ecc. Default value = no_ecc.                 |
// |---------------------------------------------------------------------------------------------------------------------|
// |                                                                                                                     |
// |   "no_ecc" - Disables ECC                                                                                           |
// |   "en_ecc" - Enables both ECC Encoder and Decoder                                                                   |
// +---------------------------------------------------------------------------------------------------------------------+
// | FIFO_DEPTH_RACH      | Integer            | Range: 16 - 4194304. Default value = 2048.                              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Defines the AXI Memory Mapped FIFO Write Depth, must be power of two                                                |
// | NOTE: The maximum FIFO size (width x depth) is limited to 150-Megabits.                                             |
// +---------------------------------------------------------------------------------------------------------------------+
// | FIFO_DEPTH_RDCH      | Integer            | Range: 16 - 4194304. Default value = 2048.                              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Defines the AXI Memory Mapped FIFO Write Depth, must be power of two                                                |
// | NOTE: The maximum FIFO size (width x depth) is limited to 150-Megabits.                                             |
// +---------------------------------------------------------------------------------------------------------------------+
// | FIFO_DEPTH_WACH      | Integer            | Range: 16 - 4194304. Default value = 2048.                              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Defines the AXI Memory Mapped FIFO Write Depth, must be power of two                                                |
// | NOTE: The maximum FIFO size (width x depth) is limited to 150-Megabits.                                             |
// +---------------------------------------------------------------------------------------------------------------------+
// | FIFO_DEPTH_WDCH      | Integer            | Range: 16 - 4194304. Default value = 2048.                              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Defines the AXI Memory Mapped FIFO Write Depth, must be power of two                                                |
// | NOTE: The maximum FIFO size (width x depth) is limited to 150-Megabits.                                             |
// +---------------------------------------------------------------------------------------------------------------------+
// | FIFO_DEPTH_WRCH      | Integer            | Range: 16 - 4194304. Default value = 2048.                              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Defines the AXI Memory Mapped FIFO Write Depth, must be power of two                                                |
// | NOTE: The maximum FIFO size (width x depth) is limited to 150-Megabits.                                             |
// +---------------------------------------------------------------------------------------------------------------------+
// | FIFO_MEMORY_TYPE_RACH| String             | Allowed values: auto, block, distributed, ultra. Default value = auto.  |
// |---------------------------------------------------------------------------------------------------------------------|
// | Designate the fifo memory primitive (resource type) to use-                                                         |
// |                                                                                                                     |
// |   "auto"- Allow Vivado Synthesis to choose                                                                          |
// |   "block"- Block RAM FIFO                                                                                           |
// |   "distributed"- Distributed RAM FIFO                                                                               |
// |   "ultra"- URAM FIFO                                                                                                |
// |                                                                                                                     |
// | NOTE: There may be a behavior mismatch if Block RAM or Ultra RAM specific features, like ECC or Asymmetry, are selected with FIFO_MEMORY_TYPE_RACH set to "auto".|
// +---------------------------------------------------------------------------------------------------------------------+
// | FIFO_MEMORY_TYPE_RDCH| String             | Allowed values: auto, block, distributed, ultra. Default value = auto.  |
// |---------------------------------------------------------------------------------------------------------------------|
// | Designate the fifo memory primitive (resource type) to use-                                                         |
// |                                                                                                                     |
// |   "auto"- Allow Vivado Synthesis to choose                                                                          |
// |   "block"- Block RAM FIFO                                                                                           |
// |   "distributed"- Distributed RAM FIFO                                                                               |
// |   "ultra"- URAM FIFO                                                                                                |
// |                                                                                                                     |
// | NOTE: There may be a behavior mismatch if Block RAM or Ultra RAM specific features, like ECC or Asymmetry, are selected with FIFO_MEMORY_TYPE_RDCH set to "auto".|
// +---------------------------------------------------------------------------------------------------------------------+
// | FIFO_MEMORY_TYPE_WACH| String             | Allowed values: auto, block, distributed, ultra. Default value = auto.  |
// |---------------------------------------------------------------------------------------------------------------------|
// | Designate the fifo memory primitive (resource type) to use-                                                         |
// |                                                                                                                     |
// |   "auto"- Allow Vivado Synthesis to choose                                                                          |
// |   "block"- Block RAM FIFO                                                                                           |
// |   "distributed"- Distributed RAM FIFO                                                                               |
// |   "ultra"- URAM FIFO                                                                                                |
// |                                                                                                                     |
// | NOTE: There may be a behavior mismatch if Block RAM or Ultra RAM specific features, like ECC or Asymmetry, are selected with FIFO_MEMORY_TYPE_WACH set to "auto".|
// +---------------------------------------------------------------------------------------------------------------------+
// | FIFO_MEMORY_TYPE_WDCH| String             | Allowed values: auto, block, distributed, ultra. Default value = auto.  |
// |---------------------------------------------------------------------------------------------------------------------|
// | Designate the fifo memory primitive (resource type) to use-                                                         |
// |                                                                                                                     |
// |   "auto"- Allow Vivado Synthesis to choose                                                                          |
// |   "block"- Block RAM FIFO                                                                                           |
// |   "distributed"- Distributed RAM FIFO                                                                               |
// |   "ultra"- URAM FIFO                                                                                                |
// |                                                                                                                     |
// | NOTE: There may be a behavior mismatch if Block RAM or Ultra RAM specific features, like ECC or Asymmetry, are selected with FIFO_MEMORY_TYPE_WDCH set to "auto".|
// +---------------------------------------------------------------------------------------------------------------------+
// | FIFO_MEMORY_TYPE_WRCH| String             | Allowed values: auto, block, distributed, ultra. Default value = auto.  |
// |---------------------------------------------------------------------------------------------------------------------|
// | Designate the fifo memory primitive (resource type) to use-                                                         |
// |                                                                                                                     |
// |   "auto"- Allow Vivado Synthesis to choose                                                                          |
// |   "block"- Block RAM FIFO                                                                                           |
// |   "distributed"- Distributed RAM FIFO                                                                               |
// |   "ultra"- URAM FIFO                                                                                                |
// |                                                                                                                     |
// | NOTE: There may be a behavior mismatch if Block RAM or Ultra RAM specific features, like ECC or Asymmetry, are selected with FIFO_MEMORY_TYPE_WRCH set to "auto".|
// +---------------------------------------------------------------------------------------------------------------------+
// | PROG_EMPTY_THRESH_RDCH| Integer            | Range: 5 - 4194301. Default value = 10.                                 |
// |---------------------------------------------------------------------------------------------------------------------|
// | Specifies the minimum number of read words in the FIFO at or below which prog_empty is asserted.                    |
// |                                                                                                                     |
// |   Min_Value = 5                                                                                                     |
// |   Max_Value = FIFO_WRITE_DEPTH - 5                                                                                  |
// |                                                                                                                     |
// | NOTE: The default threshold value is dependent on default FIFO_WRITE_DEPTH value. If FIFO_WRITE_DEPTH value is      |
// | changed, ensure the threshold value is within the valid range though the programmable flags are not used.           |
// +---------------------------------------------------------------------------------------------------------------------+
// | PROG_EMPTY_THRESH_WDCH| Integer            | Range: 5 - 4194301. Default value = 10.                                 |
// |---------------------------------------------------------------------------------------------------------------------|
// | Specifies the minimum number of read words in the FIFO at or below which prog_empty is asserted.                    |
// |                                                                                                                     |
// |   Min_Value = 5                                                                                                     |
// |   Max_Value = FIFO_WRITE_DEPTH - 5                                                                                  |
// |                                                                                                                     |
// | NOTE: The default threshold value is dependent on default FIFO_WRITE_DEPTH value. If FIFO_WRITE_DEPTH value is      |
// | changed, ensure the threshold value is within the valid range though the programmable flags are not used.           |
// +---------------------------------------------------------------------------------------------------------------------+
// | PROG_FULL_THRESH_RDCH| Integer            | Range: 5 - 4194301. Default value = 10.                                 |
// |---------------------------------------------------------------------------------------------------------------------|
// | Specifies the maximum number of write words in the FIFO at or above which prog_full is asserted.                    |
// |                                                                                                                     |
// |   Min_Value = 5 + CDC_SYNC_STAGES                                                                                   |
// |   Max_Value = FIFO_WRITE_DEPTH - 5                                                                                  |
// |                                                                                                                     |
// | NOTE: The default threshold value is dependent on default FIFO_WRITE_DEPTH value. If FIFO_WRITE_DEPTH value is      |
// | changed, ensure the threshold value is within the valid range though the programmable flags are not used.           |
// +---------------------------------------------------------------------------------------------------------------------+
// | PROG_FULL_THRESH_WDCH| Integer            | Range: 5 - 4194301. Default value = 10.                                 |
// |---------------------------------------------------------------------------------------------------------------------|
// | Specifies the maximum number of write words in the FIFO at or above which prog_full is asserted.                    |
// |                                                                                                                     |
// |   Min_Value = 5 + CDC_SYNC_STAGES                                                                                   |
// |   Max_Value = FIFO_WRITE_DEPTH - 5                                                                                  |
// |                                                                                                                     |
// | NOTE: The default threshold value is dependent on default FIFO_WRITE_DEPTH value. If FIFO_WRITE_DEPTH value is      |
// | changed, ensure the threshold value is within the valid range though the programmable flags are not used.           |
// +---------------------------------------------------------------------------------------------------------------------+
// | RD_DATA_COUNT_WIDTH_RDCH| Integer            | Range: 1 - 23. Default value = 1.                                       |
// |---------------------------------------------------------------------------------------------------------------------|
// | Specifies the width of rd_data_count_rdch. To reflect the correct value, the width should be log2(FIFO_DEPTH)+1.    |
// +---------------------------------------------------------------------------------------------------------------------+
// | RD_DATA_COUNT_WIDTH_WDCH| Integer            | Range: 1 - 23. Default value = 1.                                       |
// |---------------------------------------------------------------------------------------------------------------------|
// | Specifies the width of rd_data_count_wdch. To reflect the correct value, the width should be log2(FIFO_DEPTH)+1.    |
// +---------------------------------------------------------------------------------------------------------------------+
// | SIM_ASSERT_CHK       | Integer            | Range: 0 - 1. Default value = 0.                                        |
// |---------------------------------------------------------------------------------------------------------------------|
// | 0- Disable simulation message reporting. Messages related to potential misuse will not be reported.                 |
// | 1- Enable simulation message reporting. Messages related to potential misuse will be reported.                      |
// +---------------------------------------------------------------------------------------------------------------------+
// | USE_ADV_FEATURES_RDCH| String             | Default value = 1000.                                                   |
// |---------------------------------------------------------------------------------------------------------------------|
// | Enables rd_data_count_rdch, prog_empty_rdch, wr_data_count_rdch, prog_full_rdch sideband signals.                   |
// |                                                                                                                     |
// |   Setting USE_ADV_FEATURES_RDCH[1] to 1 enables prog_full_rdch flag;    Default value of this bit is 0              |
// |   Setting USE_ADV_FEATURES_RDCH[2]  to 1 enables wr_data_count_rdch;     Default value of this bit is 0             |
// |   Setting USE_ADV_FEATURES_RDCH[9]  to 1 enables prog_empty_rdch flag;   Default value of this bit is 0             |
// |   Setting USE_ADV_FEATURES_RDCH[10] to 1 enables rd_data_count_rdch;     Default value of this bit is 0             |
// +---------------------------------------------------------------------------------------------------------------------+
// | USE_ADV_FEATURES_WDCH| String             | Default value = 1000.                                                   |
// |---------------------------------------------------------------------------------------------------------------------|
// | Enables rd_data_count_wdch, prog_empty_wdch, wr_data_count_wdch, prog_full_wdch sideband signals.                   |
// |                                                                                                                     |
// |   Setting USE_ADV_FEATURES_WDCH[1] to 1 enables prog_full_wdch flag;    Default value of this bit is 0              |
// |   Setting USE_ADV_FEATURES_WDCH[2]  to 1 enables wr_data_count_wdch;     Default value of this bit is 0             |
// |   Setting USE_ADV_FEATURES_WDCH[9]  to 1 enables prog_empty_wdch flag;   Default value of this bit is 0             |
// |   Setting USE_ADV_FEATURES_WDCH[10] to 1 enables rd_data_count_wdch;     Default value of this bit is 0             |
// +---------------------------------------------------------------------------------------------------------------------+
// | WR_DATA_COUNT_WIDTH_RDCH| Integer            | Range: 1 - 23. Default value = 1.                                       |
// |---------------------------------------------------------------------------------------------------------------------|
// | Specifies the width of wr_data_count_rdch. To reflect the correct value, the width should be log2(FIFO_DEPTH)+1.    |
// +---------------------------------------------------------------------------------------------------------------------+
// | WR_DATA_COUNT_WIDTH_WDCH| Integer            | Range: 1 - 23. Default value = 1.                                       |
// |---------------------------------------------------------------------------------------------------------------------|
// | Specifies the width of wr_data_count_wdch. To reflect the correct value, the width should be log2(FIFO_DEPTH)+1.    |
// +---------------------------------------------------------------------------------------------------------------------+

// Port usage table, organized as follows:
// +---------------------------------------------------------------------------------------------------------------------+
// | Port name      | Direction | Size, in bits                         | Domain  | Sense       | Handling if unused     |
// |---------------------------------------------------------------------------------------------------------------------|
// | Description                                                                                                         |
// +---------------------------------------------------------------------------------------------------------------------+
// +---------------------------------------------------------------------------------------------------------------------+
// | dbiterr_rdch   | Output    | 1                                     | m_aclk  | Active-high | DoNotCare              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Double Bit Error- Indicates that the ECC decoder detected a double-bit error and data in the FIFO core is corrupted.|
// +---------------------------------------------------------------------------------------------------------------------+
// | dbiterr_wdch   | Output    | 1                                     | m_aclk  | Active-high | DoNotCare              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Double Bit Error- Indicates that the ECC decoder detected a double-bit error and data in the FIFO core is corrupted.|
// +---------------------------------------------------------------------------------------------------------------------+
// | injectdbiterr_rdch| Input     | 1                                     | s_aclk  | Active-high | Tie to 1'b0            |
// |---------------------------------------------------------------------------------------------------------------------|
// | Double Bit Error Injection- Injects a double bit error if the ECC feature is used.                                  |
// +---------------------------------------------------------------------------------------------------------------------+
// | injectdbiterr_wdch| Input     | 1                                     | s_aclk  | Active-high | Tie to 1'b0            |
// |---------------------------------------------------------------------------------------------------------------------|
// | Double Bit Error Injection- Injects a double bit error if the ECC feature is used.                                  |
// +---------------------------------------------------------------------------------------------------------------------+
// | injectsbiterr_rdch| Input     | 1                                     | s_aclk  | Active-high | Tie to 1'b0            |
// |---------------------------------------------------------------------------------------------------------------------|
// | Single Bit Error Injection- Injects a single bit error if the ECC feature is used.                                  |
// +---------------------------------------------------------------------------------------------------------------------+
// | injectsbiterr_wdch| Input     | 1                                     | s_aclk  | Active-high | Tie to 1'b0            |
// |---------------------------------------------------------------------------------------------------------------------|
// | Single Bit Error Injection- Injects a single bit error if the ECC feature is used.                                  |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_aclk         | Input     | 1                                     | NA      | Rising edge | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | Master Interface Clock: All signals on master interface are sampled on the rising edge of this clock.               |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axi_araddr   | Output    | AXI_ADDR_WIDTH                        | m_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | ARADDR: The read address bus gives the initial address of a read burst transaction. Only the start address of the burst is provided and the control signals that are issued alongside the address detail how the address is calculated for the remaining transfers in the burst.|
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axi_arprot   | Output    | 2                                     | m_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | ARPROT: Indicates the normal, privileged, or secure protection level of the transaction and whether the transaction is a data access or an instruction access.|
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axi_arready  | Input     | 1                                     | m_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | ARREADY: Indicates that the master can accept a transfer in the current cycle.                                      |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axi_arvalid  | Output    | 1                                     | m_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | ARVALID: Indicates that the master is driving a valid transfer.                                                     |
// |                                                                                                                     |
// |   A transfer takes place when both ARVALID and ARREADY are asserted                                                 |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axi_awaddr   | Output    | AXI_ADDR_WIDTH                        | m_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | AWADDR: The write address bus gives the address of the first transfer in a write burst transaction. The associated control signals are used to determine the addresses of the remaining transfers in the burst.|
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axi_awprot   | Output    | 2                                     | m_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | AWPROT: Indicates the normal, privileged, or secure protection level of the transaction and whether the transaction is a data access or an instruction access.|
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axi_awready  | Input     | 1                                     | m_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | AWREADY: Indicates that the master can accept a transfer in the current cycle.                                      |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axi_awvalid  | Output    | 1                                     | m_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | AWVALID: Indicates that the master is driving a valid transfer.                                                     |
// |                                                                                                                     |
// |   A transfer takes place when both AWVALID and AWREADY are asserted                                                 |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axi_bready   | Output    | 1                                     | m_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | BREADY: Indicates that the master can accept a transfer in the current cycle.                                       |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axi_bresp    | Input     | 2                                     | m_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | BRESP: Write Response. Indicates the status of the write transaction. The allowable responses are OKAY, EXOKAY, SLVERR, and DECERR.|
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axi_bvalid   | Input     | 1                                     | m_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | BVALID: Indicates that the master is driving a valid transfer.                                                      |
// |                                                                                                                     |
// |   A transfer takes place when both BVALID and BREADY are asserted                                                   |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axi_rdata    | Input     | AXI_DATA_WIDTH                        | m_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | RDATA: The primary payload that is used to provide the data that is passing across the interface. The width         |
// | of the data payload is an integer number of bytes.                                                                  |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axi_rready   | Output    | 1                                     | m_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | RREADY: Indicates that the master can accept a transfer in the current cycle.                                       |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axi_rresp    | Input     | 2                                     | m_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | RRESP: Indicates the status of the read transfer. The allowable responses are OKAY, EXOKAY, SLVERR, and DECERR.     |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axi_rvalid   | Input     | 1                                     | m_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | RVALID: Indicates that the master is driving a valid transfer.                                                      |
// |                                                                                                                     |
// |   A transfer takes place when both RVALID and RREADY are asserted                                                   |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axi_wdata    | Output    | AXI_DATA_WIDTH                        | m_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | WDATA: The primary payload that is used to provide the data that is passing across the interface. The width         |
// | of the data payload is an integer number of bytes.                                                                  |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axi_wready   | Input     | 1                                     | m_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | WREADY: Indicates that the master can accept a transfer in the current cycle.                                       |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axi_wstrb    | Output    | AXI_DATA_WIDTH                        | m_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | WSTRB: The byte qualifier that indicates whether the content of the associated byte of TDATA is processed           |
// | as a data byte or a position byte. For a 64-bit DATA, bit 0 corresponds to the least significant byte on            |
// | DATA, and bit 0 corresponds to the least significant byte on DATA, and bit 7 corresponds to the most significant    |
// | byte. For example:                                                                                                  |
// |                                                                                                                     |
// |   STROBE[0] = 1b, DATA[7:0] is valid                                                                                |
// |   STROBE[7] = 0b, DATA[63:56] is not valid                                                                          |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axi_wvalid   | Output    | 1                                     | m_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | WVALID: Indicates that the master is driving a valid transfer.                                                      |
// |                                                                                                                     |
// |   A transfer takes place when both WVALID and WREADY are asserted                                                   |
// +---------------------------------------------------------------------------------------------------------------------+
// | prog_empty_rdch| Output    | 1                                     | m_aclk  | Active-high | DoNotCare              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Programmable Empty- This signal is asserted when the number of words in the Read Data Channel FIFO is less than or equal|
// | to the programmable empty threshold value.                                                                          |
// | It is de-asserted when the number of words in the Read Data Channel FIFO exceeds the programmable empty threshold value.|
// +---------------------------------------------------------------------------------------------------------------------+
// | prog_empty_wdch| Output    | 1                                     | m_aclk  | Active-high | DoNotCare              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Programmable Empty- This signal is asserted when the number of words in the Write Data Channel FIFO is less than or equal|
// | to the programmable empty threshold value.                                                                          |
// | It is de-asserted when the number of words in the Write Data Channel FIFO exceeds the programmable empty threshold value.|
// +---------------------------------------------------------------------------------------------------------------------+
// | prog_full_rdch | Output    | 1                                     | s_aclk  | Active-high | DoNotCare              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Programmable Full: This signal is asserted when the number of words in the Read Data Channel FIFO is greater than or equal|
// | to the programmable full threshold value.                                                                           |
// | It is de-asserted when the number of words in the Read Data Channel FIFO is less than the programmable full threshold value.|
// +---------------------------------------------------------------------------------------------------------------------+
// | prog_full_wdch | Output    | 1                                     | s_aclk  | Active-high | DoNotCare              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Programmable Full: This signal is asserted when the number of words in the Write Data Channel FIFO is greater than or equal|
// | to the programmable full threshold value.                                                                           |
// | It is de-asserted when the number of words in the Write Data Channel FIFO is less than the programmable full threshold value.|
// +---------------------------------------------------------------------------------------------------------------------+
// | rd_data_count_rdch| Output    | RD_DATA_COUNT_WIDTH_RDCH              | m_aclk  | NA          | DoNotCare              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Read Data Count- This bus indicates the number of words available for reading in the Read Data Channel FIFO.        |
// +---------------------------------------------------------------------------------------------------------------------+
// | rd_data_count_wdch| Output    | RD_DATA_COUNT_WIDTH_WDCH              | m_aclk  | NA          | DoNotCare              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Read Data Count- This bus indicates the number of words available for reading in the Write Data Channel FIFO.       |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_aclk         | Input     | 1                                     | NA      | Rising edge | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | Slave Interface Clock: All signals on slave interface are sampled on the rising edge of this clock.                 |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_aresetn      | Input     | 1                                     | NA      | Active-low  | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | Active low asynchronous reset.                                                                                      |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axi_araddr   | Input     | AXI_ADDR_WIDTH                        | s_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | ARADDR: The read address bus gives the initial address of a read burst transaction. Only the start address of the burst is provided and the control signals that are issued alongside the address detail how the address is calculated for the remaining transfers in the burst.|
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axi_arprot   | Input     | 2                                     | s_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | ARPROT: Indicates the normal, privileged, or secure protection level of the transaction and whether the transaction is a data access or an instruction access.|
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axi_arready  | Output    | 1                                     | s_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | ARREADY: Indicates that the slave can accept a transfer in the current cycle.                                       |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axi_arvalid  | Input     | 1                                     | s_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | ARVALID: Indicates that the master is driving a valid transfer.                                                     |
// |                                                                                                                     |
// |   A transfer takes place when both ARVALID and ARREADY are asserted                                                 |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axi_awaddr   | Input     | AXI_ADDR_WIDTH                        | s_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | AWADDR: The write address bus gives the address of the first transfer in a write burst transaction. The associated control signals are used to determine the addresses of the remaining transfers in the burst.|
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axi_awprot   | Input     | 2                                     | s_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | AWPROT: Indicates the normal, privileged, or secure protection level of the transaction and whether the transaction is a data access or an instruction access.|
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axi_awready  | Output    | 1                                     | s_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | AWREADY: Indicates that the slave can accept a transfer in the current cycle.                                       |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axi_awvalid  | Input     | 1                                     | s_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | AWVALID: Indicates that the master is driving a valid transfer.                                                     |
// |                                                                                                                     |
// |   A transfer takes place when both AWVALID and AWREADY are asserted                                                 |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axi_bready   | Input     | 1                                     | s_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | BREADY: Indicates that the slave can accept a transfer in the current cycle.                                        |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axi_bresp    | Output    | 2                                     | s_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | BRESP: Write Response. Indicates the status of the write transaction. The allowable responses are OKAY, EXOKAY, SLVERR, and DECERR.|
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axi_bvalid   | Output    | 1                                     | s_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | BVALID: Indicates that the master is driving a valid transfer.                                                      |
// |                                                                                                                     |
// |   A transfer takes place when both BVALID and BREADY are asserted                                                   |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axi_rdata    | Output    | AXI_DATA_WIDTH                        | s_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | RDATA: The primary payload that is used to provide the data that is passing across the interface. The width         |
// | of the data payload is an integer number of bytes.                                                                  |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axi_rready   | Input     | 1                                     | s_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | RREADY: Indicates that the slave can accept a transfer in the current cycle.                                        |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axi_rresp    | Output    | 2                                     | s_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | RRESP: Indicates the status of the read transfer. The allowable responses are OKAY, EXOKAY, SLVERR, and DECERR.     |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axi_rvalid   | Output    | 1                                     | s_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | RVALID: Indicates that the master is driving a valid transfer.                                                      |
// |                                                                                                                     |
// |   A transfer takes place when both RVALID and RREADY are asserted                                                   |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axi_wdata    | Input     | AXI_DATA_WIDTH                        | s_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | WDATA: The primary payload that is used to provide the data that is passing across the interface. The width         |
// | of the data payload is an integer number of bytes.                                                                  |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axi_wready   | Output    | 1                                     | s_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | WREADY: Indicates that the slave can accept a transfer in the current cycle.                                        |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axi_wstrb    | Input     | AXI_DATA_WIDTH                        | s_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | WSTRB: The byte qualifier that indicates whether the content of the associated byte of TDATA is processed           |
// | as a data byte or a position byte. For a 64-bit DATA, bit 0 corresponds to the least significant byte on            |
// | DATA, and bit 0 corresponds to the least significant byte on DATA, and bit 7 corresponds to the most significant    |
// | byte. For example:                                                                                                  |
// |                                                                                                                     |
// |   STROBE[0] = 1b, DATA[7:0] is valid                                                                                |
// |   STROBE[7] = 0b, DATA[63:56] is not valid                                                                          |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axi_wvalid   | Input     | 1                                     | s_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | WVALID: Indicates that the master is driving a valid transfer.                                                      |
// |                                                                                                                     |
// |   A transfer takes place when both WVALID and WREADY are asserted                                                   |
// +---------------------------------------------------------------------------------------------------------------------+
// | sbiterr_rdch   | Output    | 1                                     | m_aclk  | Active-high | DoNotCare              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Single Bit Error- Indicates that the ECC decoder detected and fixed a single-bit error.                             |
// +---------------------------------------------------------------------------------------------------------------------+
// | sbiterr_wdch   | Output    | 1                                     | m_aclk  | Active-high | DoNotCare              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Single Bit Error- Indicates that the ECC decoder detected and fixed a single-bit error.                             |
// +---------------------------------------------------------------------------------------------------------------------+
// | wr_data_count_rdch| Output    | WR_DATA_COUNT_WIDTH_RDCH              | s_aclk  | NA          | DoNotCare              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Write Data Count: This bus indicates the number of words written into the Read Data Channel FIFO.                   |
// +---------------------------------------------------------------------------------------------------------------------+
// | wr_data_count_wdch| Output    | WR_DATA_COUNT_WIDTH_WDCH              | s_aclk  | NA          | DoNotCare              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Write Data Count: This bus indicates the number of words written into the Write Data Channel FIFO.                  |
// +---------------------------------------------------------------------------------------------------------------------+


// xpm_fifo_axil : In order to incorporate this function into the design,
//    Verilog    : the following instance declaration needs to be placed
//   instance    : in the body of the design code.  The instance name
//  declaration  : (xpm_fifo_axil_inst) and/or the port declarations within the
//     code      : parenthesis may be changed to properly reference and
//               : connect this function to the design.  All inputs
//               : and outputs must be connected.

//  Please reference the appropriate libraries guide for additional information on the XPM modules.

//  <-----Cut code below this line---->

   // xpm_fifo_axil: AXI Memory Mapped (AXI Lite) FIFO
   // Xilinx Parameterized Macro, version 2019.1

   xpm_fifo_axil #(
      .AXI_ADDR_WIDTH(32),            // DECIMAL
      .AXI_DATA_WIDTH(32),            // DECIMAL
      .CDC_SYNC_STAGES(2),            // DECIMAL
      .CLOCKING_MODE("common_clock"), // String
      .ECC_MODE_RDCH("no_ecc"),       // String
      .ECC_MODE_WDCH("no_ecc"),       // String
      .FIFO_DEPTH_RACH(2048),         // DECIMAL
      .FIFO_DEPTH_RDCH(2048),         // DECIMAL
      .FIFO_DEPTH_WACH(2048),         // DECIMAL
      .FIFO_DEPTH_WDCH(2048),         // DECIMAL
      .FIFO_DEPTH_WRCH(2048),         // DECIMAL
      .FIFO_MEMORY_TYPE_RACH("auto"), // String
      .FIFO_MEMORY_TYPE_RDCH("auto"), // String
      .FIFO_MEMORY_TYPE_WACH("auto"), // String
      .FIFO_MEMORY_TYPE_WDCH("auto"), // String
      .FIFO_MEMORY_TYPE_WRCH("auto"), // String
      .PROG_EMPTY_THRESH_RDCH(10),    // DECIMAL
      .PROG_EMPTY_THRESH_WDCH(10),    // DECIMAL
      .PROG_FULL_THRESH_RDCH(10),     // DECIMAL
      .PROG_FULL_THRESH_WDCH(10),     // DECIMAL
      .RD_DATA_COUNT_WIDTH_RDCH(1),   // DECIMAL
      .RD_DATA_COUNT_WIDTH_WDCH(1),   // DECIMAL
      .SIM_ASSERT_CHK(0),             // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .USE_ADV_FEATURES_RDCH("1000"), // String
      .USE_ADV_FEATURES_WDCH("1000"), // String
      .WR_DATA_COUNT_WIDTH_RDCH(1),   // DECIMAL
      .WR_DATA_COUNT_WIDTH_WDCH(1)    // DECIMAL
   )
   xpm_fifo_axil_inst (
      .dbiterr_rdch(dbiterr_rdch),             // 1-bit output: Double Bit Error- Indicates that the ECC
                                               // decoder detected a double-bit error and data in the FIFO core
                                               // is corrupted.

      .dbiterr_wdch(dbiterr_wdch),             // 1-bit output: Double Bit Error- Indicates that the ECC
                                               // decoder detected a double-bit error and data in the FIFO core
                                               // is corrupted.

      .m_axi_araddr(m_axi_araddr),             // AXI_ADDR_WIDTH-bit output: ARADDR: The read address bus gives
                                               // the initial address of a read burst transaction. Only the
                                               // start address of the burst is provided and the control
                                               // signals that are issued alongside the address detail how the
                                               // address is calculated for the remaining transfers in the
                                               // burst.

      .m_axi_arprot(m_axi_arprot),             // 2-bit output: ARPROT: Indicates the normal, privileged, or
                                               // secure protection level of the transaction and whether the
                                               // transaction is a data access or an instruction access.

      .m_axi_arvalid(m_axi_arvalid),           // 1-bit output: ARVALID: Indicates that the master is driving a
                                               // valid transfer. A transfer takes place when both ARVALID and
                                               // ARREADY are asserted

      .m_axi_awaddr(m_axi_awaddr),             // AXI_ADDR_WIDTH-bit output: AWADDR: The write address bus
                                               // gives the address of the first transfer in a write burst
                                               // transaction. The associated control signals are used to
                                               // determine the addresses of the remaining transfers in the
                                               // burst.

      .m_axi_awprot(m_axi_awprot),             // 2-bit output: AWPROT: Indicates the normal, privileged, or
                                               // secure protection level of the transaction and whether the
                                               // transaction is a data access or an instruction access.

      .m_axi_awvalid(m_axi_awvalid),           // 1-bit output: AWVALID: Indicates that the master is driving a
                                               // valid transfer. A transfer takes place when both AWVALID and
                                               // AWREADY are asserted

      .m_axi_bready(m_axi_bready),             // 1-bit output: BREADY: Indicates that the master can accept a
                                               // transfer in the current cycle.

      .m_axi_rready(m_axi_rready),             // 1-bit output: RREADY: Indicates that the master can accept a
                                               // transfer in the current cycle.

      .m_axi_wdata(m_axi_wdata),               // AXI_DATA_WIDTH-bit output: WDATA: The primary payload that is
                                               // used to provide the data that is passing across the
                                               // interface. The width of the data payload is an integer number
                                               // of bytes.

      .m_axi_wstrb(m_axi_wstrb),               // AXI_DATA_WIDTH-bit output: WSTRB: The byte qualifier that
                                               // indicates whether the content of the associated byte of TDATA
                                               // is processed as a data byte or a position byte. For a 64-bit
                                               // DATA, bit 0 corresponds to the least significant byte on
                                               // DATA, and bit 0 corresponds to the least significant byte on
                                               // DATA, and bit 7 corresponds to the most significant byte. For
                                               // example: STROBE[0] = 1b, DATA[7:0] is valid STROBE[7] = 0b,
                                               // DATA[63:56] is not valid

      .m_axi_wvalid(m_axi_wvalid),             // 1-bit output: WVALID: Indicates that the master is driving a
                                               // valid transfer. A transfer takes place when both WVALID and
                                               // WREADY are asserted

      .prog_empty_rdch(prog_empty_rdch),       // 1-bit output: Programmable Empty- This signal is asserted
                                               // when the number of words in the Read Data Channel FIFO is
                                               // less than or equal to the programmable empty threshold value.
                                               // It is de-asserted when the number of words in the Read Data
                                               // Channel FIFO exceeds the programmable empty threshold value.

      .prog_empty_wdch(prog_empty_wdch),       // 1-bit output: Programmable Empty- This signal is asserted
                                               // when the number of words in the Write Data Channel FIFO is
                                               // less than or equal to the programmable empty threshold value.
                                               // It is de-asserted when the number of words in the Write Data
                                               // Channel FIFO exceeds the programmable empty threshold value.

      .prog_full_rdch(prog_full_rdch),         // 1-bit output: Programmable Full: This signal is asserted when
                                               // the number of words in the Read Data Channel FIFO is greater
                                               // than or equal to the programmable full threshold value. It is
                                               // de-asserted when the number of words in the Read Data Channel
                                               // FIFO is less than the programmable full threshold value.

      .prog_full_wdch(prog_full_wdch),         // 1-bit output: Programmable Full: This signal is asserted when
                                               // the number of words in the Write Data Channel FIFO is greater
                                               // than or equal to the programmable full threshold value. It is
                                               // de-asserted when the number of words in the Write Data
                                               // Channel FIFO is less than the programmable full threshold
                                               // value.

      .rd_data_count_rdch(rd_data_count_rdch), // RD_DATA_COUNT_WIDTH_RDCH-bit output: Read Data Count- This
                                               // bus indicates the number of words available for reading in
                                               // the Read Data Channel FIFO.

      .rd_data_count_wdch(rd_data_count_wdch), // RD_DATA_COUNT_WIDTH_WDCH-bit output: Read Data Count- This
                                               // bus indicates the number of words available for reading in
                                               // the Write Data Channel FIFO.

      .s_axi_arready(s_axi_arready),           // 1-bit output: ARREADY: Indicates that the slave can accept a
                                               // transfer in the current cycle.

      .s_axi_awready(s_axi_awready),           // 1-bit output: AWREADY: Indicates that the slave can accept a
                                               // transfer in the current cycle.

      .s_axi_bresp(s_axi_bresp),               // 2-bit output: BRESP: Write Response. Indicates the status of
                                               // the write transaction. The allowable responses are OKAY,
                                               // EXOKAY, SLVERR, and DECERR.

      .s_axi_bvalid(s_axi_bvalid),             // 1-bit output: BVALID: Indicates that the master is driving a
                                               // valid transfer. A transfer takes place when both BVALID and
                                               // BREADY are asserted

      .s_axi_rdata(s_axi_rdata),               // AXI_DATA_WIDTH-bit output: RDATA: The primary payload that is
                                               // used to provide the data that is passing across the
                                               // interface. The width of the data payload is an integer number
                                               // of bytes.

      .s_axi_rresp(s_axi_rresp),               // 2-bit output: RRESP: Indicates the status of the read
                                               // transfer. The allowable responses are OKAY, EXOKAY, SLVERR,
                                               // and DECERR.

      .s_axi_rvalid(s_axi_rvalid),             // 1-bit output: RVALID: Indicates that the master is driving a
                                               // valid transfer. A transfer takes place when both RVALID and
                                               // RREADY are asserted

      .s_axi_wready(s_axi_wready),             // 1-bit output: WREADY: Indicates that the slave can accept a
                                               // transfer in the current cycle.

      .sbiterr_rdch(sbiterr_rdch),             // 1-bit output: Single Bit Error- Indicates that the ECC
                                               // decoder detected and fixed a single-bit error.

      .sbiterr_wdch(sbiterr_wdch),             // 1-bit output: Single Bit Error- Indicates that the ECC
                                               // decoder detected and fixed a single-bit error.

      .wr_data_count_rdch(wr_data_count_rdch), // WR_DATA_COUNT_WIDTH_RDCH-bit output: Write Data Count: This
                                               // bus indicates the number of words written into the Read Data
                                               // Channel FIFO.

      .wr_data_count_wdch(wr_data_count_wdch), // WR_DATA_COUNT_WIDTH_WDCH-bit output: Write Data Count: This
                                               // bus indicates the number of words written into the Write Data
                                               // Channel FIFO.

      .injectdbiterr_rdch(injectdbiterr_rdch), // 1-bit input: Double Bit Error Injection- Injects a double bit
                                               // error if the ECC feature is used.

      .injectdbiterr_wdch(injectdbiterr_wdch), // 1-bit input: Double Bit Error Injection- Injects a double bit
                                               // error if the ECC feature is used.

      .injectsbiterr_rdch(injectsbiterr_rdch), // 1-bit input: Single Bit Error Injection- Injects a single bit
                                               // error if the ECC feature is used.

      .injectsbiterr_wdch(injectsbiterr_wdch), // 1-bit input: Single Bit Error Injection- Injects a single bit
                                               // error if the ECC feature is used.

      .m_aclk(m_aclk),                         // 1-bit input: Master Interface Clock: All signals on master
                                               // interface are sampled on the rising edge of this clock.

      .m_axi_arready(m_axi_arready),           // 1-bit input: ARREADY: Indicates that the master can accept a
                                               // transfer in the current cycle.

      .m_axi_awready(m_axi_awready),           // 1-bit input: AWREADY: Indicates that the master can accept a
                                               // transfer in the current cycle.

      .m_axi_bresp(m_axi_bresp),               // 2-bit input: BRESP: Write Response. Indicates the status of
                                               // the write transaction. The allowable responses are OKAY,
                                               // EXOKAY, SLVERR, and DECERR.

      .m_axi_bvalid(m_axi_bvalid),             // 1-bit input: BVALID: Indicates that the master is driving a
                                               // valid transfer. A transfer takes place when both BVALID and
                                               // BREADY are asserted

      .m_axi_rdata(m_axi_rdata),               // AXI_DATA_WIDTH-bit input: RDATA: The primary payload that is
                                               // used to provide the data that is passing across the
                                               // interface. The width of the data payload is an integer number
                                               // of bytes.

      .m_axi_rresp(m_axi_rresp),               // 2-bit input: RRESP: Indicates the status of the read
                                               // transfer. The allowable responses are OKAY, EXOKAY, SLVERR,
                                               // and DECERR.

      .m_axi_rvalid(m_axi_rvalid),             // 1-bit input: RVALID: Indicates that the master is driving a
                                               // valid transfer. A transfer takes place when both RVALID and
                                               // RREADY are asserted

      .m_axi_wready(m_axi_wready),             // 1-bit input: WREADY: Indicates that the master can accept a
                                               // transfer in the current cycle.

      .s_aclk(s_aclk),                         // 1-bit input: Slave Interface Clock: All signals on slave
                                               // interface are sampled on the rising edge of this clock.

      .s_aresetn(s_aresetn),                   // 1-bit input: Active low asynchronous reset.
      .s_axi_araddr(s_axi_araddr),             // AXI_ADDR_WIDTH-bit input: ARADDR: The read address bus gives
                                               // the initial address of a read burst transaction. Only the
                                               // start address of the burst is provided and the control
                                               // signals that are issued alongside the address detail how the
                                               // address is calculated for the remaining transfers in the
                                               // burst.

      .s_axi_arprot(s_axi_arprot),             // 2-bit input: ARPROT: Indicates the normal, privileged, or
                                               // secure protection level of the transaction and whether the
                                               // transaction is a data access or an instruction access.

      .s_axi_arvalid(s_axi_arvalid),           // 1-bit input: ARVALID: Indicates that the master is driving a
                                               // valid transfer. A transfer takes place when both ARVALID and
                                               // ARREADY are asserted

      .s_axi_awaddr(s_axi_awaddr),             // AXI_ADDR_WIDTH-bit input: AWADDR: The write address bus gives
                                               // the address of the first transfer in a write burst
                                               // transaction. The associated control signals are used to
                                               // determine the addresses of the remaining transfers in the
                                               // burst.

      .s_axi_awprot(s_axi_awprot),             // 2-bit input: AWPROT: Indicates the normal, privileged, or
                                               // secure protection level of the transaction and whether the
                                               // transaction is a data access or an instruction access.

      .s_axi_awvalid(s_axi_awvalid),           // 1-bit input: AWVALID: Indicates that the master is driving a
                                               // valid transfer. A transfer takes place when both AWVALID and
                                               // AWREADY are asserted

      .s_axi_bready(s_axi_bready),             // 1-bit input: BREADY: Indicates that the slave can accept a
                                               // transfer in the current cycle.

      .s_axi_rready(s_axi_rready),             // 1-bit input: RREADY: Indicates that the slave can accept a
                                               // transfer in the current cycle.

      .s_axi_wdata(s_axi_wdata),               // AXI_DATA_WIDTH-bit input: WDATA: The primary payload that is
                                               // used to provide the data that is passing across the
                                               // interface. The width of the data payload is an integer number
                                               // of bytes.

      .s_axi_wstrb(s_axi_wstrb),               // AXI_DATA_WIDTH-bit input: WSTRB: The byte qualifier that
                                               // indicates whether the content of the associated byte of TDATA
                                               // is processed as a data byte or a position byte. For a 64-bit
                                               // DATA, bit 0 corresponds to the least significant byte on
                                               // DATA, and bit 0 corresponds to the least significant byte on
                                               // DATA, and bit 7 corresponds to the most significant byte. For
                                               // example: STROBE[0] = 1b, DATA[7:0] is valid STROBE[7] = 0b,
                                               // DATA[63:56] is not valid

      .s_axi_wvalid(s_axi_wvalid)              // 1-bit input: WVALID: Indicates that the master is driving a
                                               // valid transfer. A transfer takes place when both WVALID and
                                               // WREADY are asserted

   );

   // End of xpm_fifo_axil_inst instantiation
				

