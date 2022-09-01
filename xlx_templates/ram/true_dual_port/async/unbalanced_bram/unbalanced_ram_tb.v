`default_nettype none
`include "../async_true_dual_ram.v"
`include "unbalanced_ram.v"

module unbalanced_ram_tb #(
    parameter DATA_WIDTH_A = 64,
    parameter ADDR_WIDTH_A = 10,
    parameter DEINTERLEAVE = 2,
    parameter RAM_PERFORMANCE = "LOW_LATENCY",
    parameter MUX_LATENCY = 2,
    //localparameters...
    parameter DATA_WIDTH_B = DATA_WIDTH_A/(DEINTERLEAVE),
    parameter ADDR_WIDTH_B = ADDR_WIDTH_A+$clog2(DEINTERLEAVE)
)  (
    input wire clka,
    input wire [ADDR_WIDTH_A-1:0] addra,
    input wire [DATA_WIDTH_A-1:0] dina,
    output wire [DATA_WIDTH_A-1:0] douta,
    input wire wea,
    input wire in_valid_a,
    output wire out_valid_a,
    input wire ena,
    input wire rsta,
    input wire regcea,
    input wire clkb,
    input wire [ADDR_WIDTH_B-1:0] addrb,
    input wire [DATA_WIDTH_B-1:0] dinb,
    output wire [DATA_WIDTH_B-1:0] doutb,
    input wire web,
    input wire in_valid_b,
    output wire out_valid_b,
    input wire enb,
    input wire rstb,
    input wire regceb
);


unbalanced_ram #(
    .DATA_WIDTH_A(DATA_WIDTH_A),
    .ADDR_WIDTH_A(ADDR_WIDTH_A),
    .DEINTERLEAVE(DEINTERLEAVE),
    .RAM_PERFORMANCE(RAM_PERFORMANCE),
    .MUX_LATENCY(MUX_LATENCY),
    .DATA_WIDTH_B(DATA_WIDTH_B),
    .ADDR_WIDTH_B(ADDR_WIDTH_B)
) unbalanced_ram_inst (
    .clka(clka),
    .addra(addra),
    .dina(dina),
    .douta(douta),
    .wea(wea),
    .in_valid_a(in_valid_a),
    .out_valid_a(out_valid_a),
    .ena(ena),
    .rsta(rsta),
    .regcea(regcea),
    .clkb(clkb),
    .addrb(addrb),
    .dinb(dinb),
    .doutb(doutb),
    .web(web),
    .in_valid_b(in_valid_b),
    .out_valid_b(out_valid_b),
    .enb(enb),
    .rstb(rstb),
    .regceb(regceb)
);



endmodule
