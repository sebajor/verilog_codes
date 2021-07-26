`default_nettype none
`include "rtl/async_true_dual_ram.v"

/*
    unbalanced ram where the data size of the PORT1 is bigger than the 
    data size of the PORT2.
    Anyway they should be divisible.
    The implementation just create different rams with the PORT2 size and handle
    which one has to be written/read
*/

module unbalanced_ram #(
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
    input wire regcea,
    input wire clkb,
    input wire [ADDR_WIDTH_B-1:0] addrb,
    input wire [DATA_WIDTH_B-1:0] dinb,
    output wire [DATA_WIDTH_B-1:0] doutb,
    input wire web,
    input wire enb,
    input wire rstb,
    input wire regceb
);

localparam ITERS = 2**WIDTH_FACTOR;


wire [DATA_WIDTH_A-1:0] dout_porta;
assign douta = dout_porta;
wire [DATA_WIDTH_B*(2**WIDTH_FACTOR)-1:0] dout_portb;

genvar i;
generate 
for(i=0; i<ITERS; i=i+1)begin
    wire [DATA_WIDTH_B-1:0] sub_data = dina[DATA_WIDTH_B*i+:DATA_WIDTH_B];
    wire sub_web = (addrb[WIDTH_FACTOR-1:0]==i)&web;  //check!
    wire [DATA_WIDTH_B-1:0] sub_doutb;
    assign dout_portb[DATA_WIDTH_B*i+:DATA_WIDTH_B] = sub_doutb;
    async_true_dual_ram #(
        .RAM_WIDTH(DATA_WIDTH_B),
        .RAM_DEPTH(2**(ADDR_WIDTH_A)),
        .RAM_PERFORMANCE(RAM_PERFORMANCE),
        .INIT_FILE("")
    ) ram_inst (
        .clka(clka),
        .addra(addra),
        .dina(sub_data),
        .douta(dout_porta[DATA_WIDTH_B*i+:DATA_WIDTH_B]),
        .wea(wea),
        .ena(ena),
        .rsta(rsta),
        .regcea(regcea),
        .clkb(clkb),
        .addrb(addrb[ADDR_WIDTH_B-1:WIDTH_FACTOR]),
        .dinb(dinb),
        .doutb(sub_doutb),
        .web(sub_web),
        .enb(enb),
        .rstb(rstb),
        .regceb(regceb)
    );
end
endgenerate

//select the outputb word from the subwords bram
reg [DATA_WIDTH_B-1:0] dout;
wire [WIDTH_FACTOR-1:0] sub_addr= addrb[WIDTH_FACTOR-1:0];
always@(*)begin
    dout = dout_portb[sub_addr*DATA_WIDTH_B+:DATA_WIDTH_B];
end

assign doutb = dout;

endmodule
