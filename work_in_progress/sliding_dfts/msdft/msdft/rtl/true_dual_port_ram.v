`default_nettype none

/*
Based in the intel example
https://www.intel.com/content/www/us/en/programmable/support/support-resources/design-examples/design-software/verilog/ver-true-dual-port-ram-sclk.html
*/


module true_dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 5,
    parameter DIRECTIVE = "dfl",
    parameter INIT = 0,
    parameter INIT_FILE = "init.hex"
    //(* ram_style = "{auto | block | distributed | pipe_distributed | block_power1 | block_power2}" *)
) (
    input wire clk,
    input wire [DATA_WIDTH-1:0] dat_a, dat_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire we_a, we_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);
//ram declaration
localparam ADDR_SIZE = 2**ADDR_WIDTH;


// xst directives
//(* ram_style = "block_power2" *);
//(* ram_style = "block_power1" *);
//(* ram_style = "pipe_distributed" *);
//(* ram_style = "distributed" *);
//(* ram_style = "block" *);
//(* ram_style = "auto" *);
reg [DATA_WIDTH-1:0] ram [ADDR_SIZE-1:0];
generate 
if(INIT==1)begin
    initial begin
        $readmemh(INIT_FILE);
    end
end
endgenerate

//port A
always@(posedge clk)begin
    if(we_a)begin
        ram[addr_a] <= dat_a;
        dout_a <= dat_a;
    end
    else
        dout_a <= ram[addr_a];
end

//port B
always@(posedge clk)begin
    if(we_b)begin
        ram[addr_b] <= dat_b;
        dout_b <= dat_b;
    end
    else
        dout_b <= ram[addr_b];
end







endmodule
