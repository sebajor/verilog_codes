`default_nettype none
`include "../../primitives.v"
`include "clock_alignment.v"

module clock_alignment_tb #(
    parameter ADC_BITS = 14,
    parameter IOSTANDARD = "LVDS"
)(
    input wire data_clock_p, data_clock_n,
    input wire frame_clock_p, frame_clock_n,

    input wire async_rst,
    input wire sync_rst,

    input wire enable,

    output wire data_clk_bufio,
    output wire data_clk_div,
    output wire mmcm_locked,

    output wire [7:0] iserdes_dout,
    output wire iserdes2_bitslip,
    output wire [3:0] bitslip_count,
    output wire frame_valid
);
 
wire data_clock_n_aux = ~data_clock_p;
wire frame_clock_n_aux = ~frame_clock_p;





clock_alignment #(
    .ADC_BITS(ADC_BITS),
    .IOSTANDARD(IOSTANDARD) 
) clock_alignment_inst (
    .data_clock_p(data_clock_p), 
    .data_clock_n(data_clock_n_aux),
    .frame_clock_p(frame_clock_p),
    .frame_clock_n(frame_clock_n_aux),
    .async_rst(async_rst),
    .sync_rst(sync_rst),
    .enable(enable),
    .data_clk_bufio(data_clk_bufio),
    .data_clk_div(data_clk_div),
    .iserdes_dout(iserdes_dout),
    .iserdes2_bitslip(iserdes2_bitslip),
    .bitslip_count(bitslip_count),
    .frame_valid(frame_valid),
    .mmcm_locked(mmcm_locked)
);
 
endmodule
