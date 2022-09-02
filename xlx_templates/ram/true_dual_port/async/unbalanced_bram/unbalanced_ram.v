`default_nettype none

/*
    unbalanced ram where the data size of the PORT1 is bigger than the 
    data size of the PORT2.
    Anyway they should be divisible.
    The implementation just create different rams with the PORT2 size and handle
    which one has to be written/read

    It seems tha if you write a value in the ram doesnt update the 
    other port (eg: if you write the address 0 in the porta meanwhile the portb
    is stuck at 0 you wont see the new value)
    TODO: check if using the enable port could fix the issue.

*/

module unbalanced_ram #(
    parameter DATA_WIDTH_A = 64,
    parameter ADDR_WIDTH_A = 7,
    parameter DEINTERLEAVE = 2,
    parameter RAM_PERFORMANCE = "LOW_LATENCY",
    parameter MUX_LATENCY = 0,
    parameter RAM_TYPE = "WRITE",    //write, read, real (write first, read first, real)
    //localparameters...
    parameter DATA_WIDTH_B = DATA_WIDTH_A/(DEINTERLEAVE),
    parameter ADDR_WIDTH_B = ADDR_WIDTH_A+$clog2(DEINTERLEAVE)
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


reg [ADDR_WIDTH_A-1:0] addrb_temp=0;
wire [DATA_WIDTH_A-1:0] doutb_temp;

wire [$clog2(DEINTERLEAVE)-1:0] sub_addr = addrb[$clog2(DEINTERLEAVE)-1:0];

reg [(DEINTERLEAVE-1)*DATA_WIDTH_B-1:0] dinb_temp = 0;
reg web_temp=0;
reg [1:0] din_valid=0;

//we would have troubles to write, but reading should be direct
//there is a bug right here.. first we need two words to write the data into
//the ram and not just delay the web. Also it gives another delay for the 
//reading and that is not acceptable for axil
/*
always@(posedge clkb)begin
    addrb_temp <= addrb[ADDR_WIDTH_B-1:$clog2(DEINTERLEAVE)];
    web_temp <= web;
    dinb_temp[DATA_WIDTH_B*sub_word+:DATA_WIDTH_B] <= dinb;
    din_valid<= {din_valid[0], in_valid_b};
end
*/

reg [$clog2(DEINTERLEAVE)-1:0] full=0;
wire [5-1:0] test = {($clog2(DEINTERLEAVE)){1'b1}};
always@(posedge clkb)begin
    if((sub_addr != {($clog2(DEINTERLEAVE)){1'b1}}) & web)begin
        dinb_temp[DATA_WIDTH_B*sub_addr+:DATA_WIDTH_B] <= dinb;
        full[addrb[$clog2(DEINTERLEAVE)]] = 1'b1;
    end
    else if((sub_addr=={$clog2(DEINTERLEAVE){1'b1}})&web)
        full <=0;
end




generate
    if(RAM_TYPE=="READ")begin
        async_true_dual_read_first #(
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
            .addrb(addrb[ADDR_WIDTH_B-1:$clog2(DEINTERLEAVE)]),
            .dinb({dinb,dinb_temp}),
            .web(web & (&sub_addr)),
            .enb(enb),
            .rstb(rstb),
            .regceb(regceb),
            .doutb(doutb_temp)
        );
    end
    else if(RAM_TYPE=="WRITE")begin
        async_true_dual_ram_write_first#(
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
            .addrb(addrb[ADDR_WIDTH_B-1:$clog2(DEINTERLEAVE)]),
            .dinb({dinb,dinb_temp}),
            .web(web & (&sub_addr)),
            .enb(enb),
            .rstb(rstb),
            .regceb(regceb),
            .doutb(doutb_temp)
        );
    end
    else begin
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
            .addrb(addrb[ADDR_WIDTH_B-1:$clog2(DEINTERLEAVE)]),
            .dinb({dinb,dinb_temp}),
            .web(web & (&sub_addr)),
            .enb(enb),
            .rstb(rstb),
            .regceb(regceb),
            .doutb(doutb_temp)
        );
    end
endgenerate


//the ram respond with one cycle of delay.. so we need to delay the index
reg [$clog2(DEINTERLEAVE)-1:0]sub_addr_r=0;
always@(posedge clkb)
    sub_addr_r <= sub_addr;

//mux latency
generate 
    if(MUX_LATENCY==0)begin
        assign doutb = doutb_temp[sub_addr_r*DATA_WIDTH_B+:DATA_WIDTH_B];
    end 
    else begin
        reg [MUX_LATENCY*DATA_WIDTH_B-1:0] mux_out=0;
        reg [MUX_LATENCY-1:0] din_valid_r=0;
        always@(posedge clkb)begin
            din_valid_r <= {din_valid_r[MUX_LATENCY-2:0], din_valid[1]};
            mux_out <= {mux_out[(MUX_LATENCY-1)*DATA_WIDTH_B-1:0],
                        doutb_temp[sub_addr*DATA_WIDTH_B+:DATA_WIDTH_B]};
        end 
        assign doutb = mux_out[MUX_LATENCY*DATA_WIDTH_B-1-:DATA_WIDTH_B];
    end
endgenerate


endmodule
