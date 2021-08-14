`default_nettype none

module dram_tge #(
    parameter DRAM_FRAMES = 10  //This maps into the depth of the fifo that 
                                //receives the burst coming from the dram, the actual mem 
                                //depth is DRAM_FRAMES*8 to have a rational coefficient 
                                //between drams and tge words
) (
    input wire clk,
    input wire ce, 
    input wire [287:0] dram_data,
    input wire dram_read_valid,
    output wire [31:0] dram_read_addr,
    output wire dram_req,

    output wire [255:0] tge_data,
    output wire tge_valid,
    output wire tge_last,

    //configuration
    input wire rst,
    input wire en,
    input wire [31:0] dram_frames,  //in multiples of 9
    input wire [31:0] tge_size,     //in multiples of 8
    input wire [31:0] tge_stop,      //cycles between two eth packets
    output wire finish
);
//288*8/256 = 9, this is our less common multiple so our burst are of that size

reg [31:0] tge_stop_r=0;
always@(posedge clk)
    tge_stop <=0;


reg [31:0] stop_counter=0;
reg [31:0] pkt_counter=0;
reg [31:0] dram_addr_counter=0;

always@(posedge clk)begin
    if(rst)begin
        stop_coutner <=0;
        pkt_counter <=0;
    end

end




sync_simple_dual_ram #(
    .RAM_WIDTH(288),
    .RAM_DEPTH(DRAM_FRAMES*8),
    .RAM_PERFORMANCE("LOW_LATENCY")
) dram_addr (
    .addra(),
    .addrb(),
    .dina(),
    .clka(),
    .wea(),
    .enb(),
    .rstb(),
    .regceb(),
    .doutb()
);




endmodule
