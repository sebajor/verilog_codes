`default_nettype none

/*
*   Author: Sebastian Jorquera
*
*   This module is written in a way that the input data is less than the DRAM
*   input data, so we have to generate the packets
*
*   Just a note... its better to keep rwn in low and control the dram with the
*   cmd_valid.
*/


module roach_dram_write #(
    parameter DIN_WIDTH = 32,    //should divide perfectly 288
    parameter DRAM_ADDR = 25,
    //stupid ise dont allow $clog2 in localparam :(
    parameter CYCLES = 288/DIN_WIDTH,
    parameter CYCLES_CLOG = $clog2(CYCLES),
    parameter ADDR_CLOG = $clog2(DRAM_ADDR)
) (
    input wire clk,
    input wire rst,
    input wire en_write,

    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,

    //to the DRAM module
    output wire dram_rst, 
    output wire [DRAM_ADDR-1:0] dram_addr,   //check!
    output wire [287:0] dram_data,

    output wire [35:0] wr_be,       //byte enable
    output wire rwn,                //1:read, 0:write
    output wire [31:0] cmd_tag,
    output wire cmd_valid
);

//dont care signals
assign wr_be = {(36){1'b1}};
assign cmd_tag = 0;
assign rwn = ~en_write;

reg [$clog2(CYCLES):0] din_counter=0;
reg [288-DIN_WIDTH-1:0] dram_buffer=0;
reg [287:0] dram_din=0;

always@(posedge clk)begin
    if(rst)begin
        din_counter <={(CYCLES_CLOG+1){1'b1}};
    end
    else if(din_valid)begin
        if(din_counter==(CYCLES-1))begin
            din_counter <=0;
            //dram_din <= dram_buffer;    //check!!
            dram_din <= {din, dram_buffer};   //or something like this..
        end
        else begin
            din_counter <= din_counter+1;
            dram_buffer[din_counter*DIN_WIDTH+:DIN_WIDTH] = din;
        end
    end
end

reg [DRAM_ADDR:0] dram_addr_r={(DRAM_ADDR){1'b1}};
reg [1:0] dram_valid=0;
always@(posedge clk)begin
    if(rst)begin
        dram_addr_r <= {(DRAM_ADDR){1'b1}};
        dram_valid <= 0;
    end
    else if((din_counter==(CYCLES-1)) & din_valid)begin
        dram_valid <= {dram_valid[0], 1'b1};
        dram_addr_r <= dram_addr+1;
    end
    else
        dram_valid <= {dram_valid[0], 1'b0};
end


assign cmd_valid = |dram_valid &en_write;
assign dram_data = dram_din;
assign dram_addr = dram_addr_r;

endmodule
