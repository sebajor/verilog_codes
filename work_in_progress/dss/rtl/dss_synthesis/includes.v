//correlator stuffs
`include "../../../../dsp/complex_power/complex_power.v"
`include "../../../../dsp/complex_mult/complex_mult.v"
`include "../../../../dsp/dsp48_mult/dsp48_mult.v"
`include "../../../../dsp/data_cast/signed_cast/signed_cast.v"
`include "../../../../dsp/data_cast/unsign_cast/unsign_cast.v"
`include "../../../../dsp/accumulators/vector/vector_accumulator.v"
`include "../../../../dsp/accumulators/vector/rtl/sync_simple_dual_ram.v"
`include "../../../../dsp/correlator/correlation_mults.v"
`include "../../../../dsp/correlator/correlator.v"

//general stuffs
`include "../../../../dsp/delay/delay.v"
`include "../../../../dsp/xlx_bram/bram_infer.v"
`include "../../../../dsp/resize_data/resize_data.v"
`include "../../../../dsp/shift/shift.v"
`include "../../../../utils/skid_buffer/skid_buffer.v"

//axi stuffs
`include "../../../../axi/axil_bram/axil_bram.v"
`include "../../../../xlx_templates/ram/true_dual_port/async/async_true_dual_ram.v"
`include "../../../../xlx_templates/ram/true_dual_port/async/async_true_dual_ram_read_first.v"
`include "../../../../xlx_templates/ram/true_dual_port/async/async_true_dual_ram_write_first.v"
`include "../../../../xlx_templates/ram/true_dual_port/async/unbalanced_bram/unbalanced_ram.v"
`include "../../../../axi/axil_bram/axil_bram_arbiter.v"
`include "../../../../axi/s_axil_reg/s_axil_reg.v"
`include "../../../../axi/axil_bram_unbalanced/axil_bram_unbalanced.v"


