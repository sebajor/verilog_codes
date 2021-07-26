`default_nettype none
`include "unbalanced_ram.v"

module unbalanced_ram_tb #(
    parameter DATA_WIDTH_A = 64,
    parameter ADDR_WIDTH_A = 7,
    parameter WIDTH_FACTOR = 1, //ie datab = 64>>1=32
    parameter RAM_PERFORMANCE = "LOW_LATENCY",
    //localparameters...
    parameter DATA_WIDTH_B = DATA_WIDTH_A>>(WIDTH_FACTOR),
    parameter ADDR_WIDTH_B = ADDR_WIDTH_A+WIDTH_FACTOR
)  (
    input wire clka,
    input wire [ADDR_WIDTH_A-1:0] addra,
    input wire [DATA_WIDTH_A-1:0] dina,
    output wire [DATA_WIDTH_A-1:0] douta,
    input wire wea,
    input wire ena,
    input wire rsta,
    input wire clkb,
    input wire [ADDR_WIDTH_B-1:0] addrb,
    input wire [DATA_WIDTH_B-1:0] dinb,
    output wire [DATA_WIDTH_B-1:0] doutb,
    input wire web,
    input wire enb,
    input wire rstb,
    input wire flag 
);


unbalanced_ram #(
    .DATA_WIDTH_A(DATA_WIDTH_A),
    .ADDR_WIDTH_A(ADDR_WIDTH_A),
    .WIDTH_FACTOR(WIDTH_FACTOR),
    .RAM_PERFORMANCE(RAM_PERFORMANCE) 
) unbalanced_ram_inst  (
    .clka(clka),
    .addra(addra),
    .dina(dina),
    .douta(douta),
    .wea(wea),
    .ena(ena),
    .rsta(rsta),
    .clkb(clkb),
    .addrb(addrb),
    .dinb(dinb),
    .doutb(doutb),
    .web(web),
    .enb(enb),
    .rstb(rstb)
);

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end

endmodule
