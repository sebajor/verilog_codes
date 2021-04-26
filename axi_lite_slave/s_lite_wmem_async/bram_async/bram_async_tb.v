`default_nettype none
`include "bram_async.v"

module bram_async_tb #(
    parameter DIN_WIDTH = 32,
    parameter N_ADDR = 256,
    parameter INIT_MEM = 0,
    parameter INIT_VALS = "init.hex"

) (
    input wire wclk,
    input wire wen,
    output wire wready,
    input wire [$clog2(N_ADDR)-1:0] waddr,
    input wire [DIN_WIDTH-1:0] win,

    input wire rclk,
    input wire ren,
    input wire [$clog2(N_ADDR)-1:0] raddr,
    output wire [DIN_WIDTH-1:0] rout,
    output wire rvalid
);



bram_async #(
    .DIN_WIDTH(DIN_WIDTH),
    .N_ADDR(N_ADDR),
    .INIT_MEM(INIT_MEM),
    .INIT_VALS(INIT_VALS)
) bram_async_inst (
    .wclk(wclk),
    .wen(wen),
    .wready(wready),
    .waddr(waddr),
    .win(win),
    .rclk(rclk),
    .ren(ren),
    .raddr(raddr),
    .rout(rout),
    .rvalid(rvalid)
);


initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end
endmodule
