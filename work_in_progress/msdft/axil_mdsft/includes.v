`include "../../../xlx_templates/bram_infer.v"
`include "../comb/comb.v"
`include "../../../dsp/complex_mult/complex_mult.v"
`include "../../../dsp/dsp48_mult/dsp48_mult.v"
`include "../../../dsp/data_cast/signed_cast/signed_cast.v"
`include "../../../xlx_templates/ram/true_dual_port/async/async_true_dual_ram2.v"   //this one initialize with binary
`include "../../../utils/skid_buffer/skid_buffer.v"
`include "../../../axi/axil_bram/axil_bram_arbiter.v"
`include "../../../axi/axil_bram/axil_bram.v"

