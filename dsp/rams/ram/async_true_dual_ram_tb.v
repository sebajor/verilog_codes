`include "async_true_dual_ram.v"

module async_true_dual_ram_tb #(
  parameter RAM_WIDTH = 32,                       // Specify RAM data width
  parameter RAM_DEPTH = 1024,                     // Specify RAM depth (number of entries)
  parameter RAM_PERFORMANCE = "LOW_LATENCY", // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
  parameter INIT_FILE = ""                        // Specify name/location of RAM initialization file if using one (leave blank if not)
) (
  input [$clog2(RAM_DEPTH-1)-1:0] addra,  // Port A address bus, width determined from RAM_DEPTH
  input [$clog2(RAM_DEPTH-1)-1:0] addrb,  // Port B address bus, width determined from RAM_DEPTH
  input [RAM_WIDTH-1:0] dina,           // Port A RAM input data
  input [RAM_WIDTH-1:0] dinb,           // Port B RAM input data
  input clka,                           // Port A clock
  input clkb,                           // Port B clock
  input wea,                            // Port A write enable
  input web,                            // Port B write enable
  input ena,                            // Port A RAM Enable, for additional power savings, disable port when not in use
  input enb,                            // Port B RAM Enable, for additional power savings, disable port when not in use
  input rsta,                           // Port A output reset (does not affect memory contents)
  input rstb,                           // Port B output reset (does not affect memory contents)
  input regcea,                         // Port A output register enable
  input regceb,                         // Port B output register enable
  output [RAM_WIDTH-1:0] douta,         // Port A RAM output data
  output [RAM_WIDTH-1:0] doutb          // Port B RAM output data
);


async_true_dual_ram #(
    .RAM_WIDTH(RAM_WIDTH),
    .RAM_DEPTH(RAM_DEPTH),
    .RAM_PERFORMANCE(RAM_PERFORMANCE),
    .INIT_FILE(INIT_FILE)
) ram_inst (
  .addra(addra),
  .addrb(addrb),
  .dina(dina),
  .dinb(dinb),
  .clka(clka),
  .clkb(clkb),
  .wea(wea),
  .web(web),
  .ena(ena),
  .enb(enb),
  .rsta(rsta),
  .rstb(rstb),
  .regcea(regcea),
  .regceb(regceb),
  .douta(douta),
  .doutb(doutb)
);

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end

endmodule

