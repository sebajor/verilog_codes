`default_nettype none

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
    parameter DEINTERLEAVE = 2,
    parameter RAM_PERFORMANCE = "LOW_LATENCY",
    parameter MUX_LATENCY = 0,
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


reg [ADDR_WIDTH_A-1:0] addrb_temp=0;
wire [DATA_WIDTH_A-1:0] doutb_temp;

wire [$clog2(DEINTERLEAVE)-1:0] sub_word = addrb[$clog2(DEINTERLEAVE)-1:0];

reg [DATA_WIDTH_A-1:0] dinb_temp = 0;
reg web_temp=0;
reg [1:0] din_valid=0;

//we would have troubles to write, but reading should be direct
always@(posedge clkb)begin
    addrb_temp <= addrb[ADDR_WIDTH_B-1:$clog2(DEINTERLEAVE)];
    web_temp <= web;
    dinb_temp[DATA_WIDTH_B*sub_word+:DATA_WIDTH_B] <= dinb;
    din_valid<= {din_valid[0], in_valid_b};
end


async_true_dual_ram #(
    .RAM_WIDTH(DATA_WIDTH_A),
    .RAM_DEPTH(2**ADDR_WIDTH_A),
    .RAM_PERFORMANCE(RAM_PERFORMANCE)
) async_dual_ram_inst (
    .clka(clka),
    .addra(addra),
    .dina(dina),
    .wea(wea),
    .ena(ena),
    .rsta(rsta),
    .regcea(regcea),
    .douta(douta),
    
    .clkb(clkb),
    .addrb(addrb_temp),
    .dinb(dinb_temp),
    .web(web_temp),
    .enb(enb),
    .rstb(rstb),
    .regceb(regceb),
    .doutb(doutb_temp)
);

//mux latency
generate 
    if(MUX_LATENCY==0)begin
        assign doutb = doutb_temp[sub_word*DATA_WIDTH_B+:DATA_WIDTH_B];
        assign out_valid_b = din_valid[1];
    end 
    else begin
        reg [MUX_LATENCY*DATA_WIDTH_B-1:0] mux_out=0;
        reg [MUX_LATENCY-1:0] din_valid_r=0;
        always@(posedge clkb)begin
            din_valid_r <= {din_valid_r[MUX_LATENCY-2:0], din_valid[1]};
            mux_out <= {mux_out[(MUX_LATENCY-1)*DATA_WIDTH_B-1:0],
                        doutb_temp[sub_word*DATA_WIDTH_B+:DATA_WIDTH_B]};
        end 
        assign doutb = mux_out[MUX_LATENCY*DATA_WIDTH_B-1-:DATA_WIDTH_B];
        assign out_valid_b = din_valid_r[MUX_LATENCY-1];
    end
endgenerate


endmodule
