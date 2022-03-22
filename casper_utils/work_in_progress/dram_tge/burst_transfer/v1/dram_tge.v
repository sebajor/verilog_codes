`default_nettype none
`include "includes.v"

module dram_tge #(
    parameter FIFO_DEPTH = 16,
    parameter BUBBLE = 20,
    parameter DRAM_MAX_ADDR = 64
) (
    input wire clk,
    input wire rst,
    input wire en,

    input wire [31:0] dram_burst_size,  //must take in account the fifo size!
                                        //burst size is in multiples of 8, for each
                                        //8 words we insert a 2 cycle bubble after 
                                        //the burst finish
    input wire [31:0] tge_pkt_size,     //
    input wire [31:0] wait_pkt,         //cycles to wait between packets 
    
    input wire [24:0] dram_count_init,  //the init address of read
                                        //given by the write counter 
    input wire [287:0] dram_data,
    input wire dram_valid,
    output wire dram_request,
    output wire [31:0] dram_addr,
    input wire dram_ready,    //~empty

    output wire [255:0] tge_data,
    output wire tge_data_valid,
    output wire tge_eof,

    output wire finish
);


wire [31:0] dram_burst= dram_burst_size<<3;
wire [31:0] bubble_cycle = dram_burst_size<<1;

reg [24:0] dram_counter={32{1'b1}};
reg [15:0] dram_burst_count=0;
reg [15:0] bubble_count=0;
reg dram_read_en=0;
reg allow_read = 1;
/*read dram burst size and insert the bubbles to have time to 
parse the data in the tge format
*/

always@(posedge clk)begin
    if(rst)begin
        dram_counter <={32{1'b1}};
        dram_burst_count <=0;
    end
    else begin
        if(en & allow_read)begin
            if(dram_burst_count== dram_burst)begin
                dram_read_en <= 0;
                if(bubble_count==bubble_cycle)begin
                    bubble_count <=0;
                    dram_burst_count <= 0;
                end
                else
                    bubble_count <= bubble_count+1;
            end
            else begin
                dram_read_en <= 1;
                dram_counter <= dram_counter +1;
                dram_burst_count <= dram_burst_count+1;
            end
        end
    end
end


assign dram_addr = dram_counter;
assign dram_request = dram_read_en;



wire fifo_full, fifo_empty;
wire [287:0] fifo_rdata;
wire fifo_rvalid, fifo_rreq;

fifo_sync #(
    .DIN_WIDTH(288),
    .FIFO_DEPTH(FIFO_DEPTH)
)fifo_sync_inst  (
    .clk(clk),
    .rst(rst),
    .wdata(dram_data),
    .w_valid(dram_valid),
    .full(fifo_full),
    .empty(fifo_empty),
    .rdata(fifo_rdata),
    .r_valid(fifo_rvalid),
    .read_req(fifo_rreq)
);

dram2tge dram2tge_inst (
    .clk(clk),
    .rst(rst),
    .en(en),
    .dram_data(fifo_rdata),
    .dram_valid(fifo_rvalid),
    .dram_request(fifo_rreq),
    .dram_ready(~fifo_empty),
    .tge_data(tge_data),
    .tge_data_valid(tge_data_valid)
);

reg [31:0] tge_counter=0;
always@(posedge clk)begin
    if(rst)
        tge_counter<=0;
    else if(tge_data_valid)begin
        if(tge_counter== (tge_pkt_size-1))
            tge_counter <= 0;
        else
            tge_counter <= tge_counter+1;
    end
end

reg [31:0] wait_counter=0;
always@(posedge clk)begin
    if((tge_counter == tge_pkt_size) | (dram_addr== DRAM_MAX_ADDR-1))begin
        allow_read <= 0;
    end
    else if(~allow_read)begin
        if(wait_counter==(wait_pkt-1))begin
            wait_counter <=0;
            allow_read <= 1;
        end
        else
            wait_counter <= wait_counter+1;
    end
end

assign tge_eof = (tge_counter == (tge_pkt_size-1)) & tge_data_valid;

assign finish = (dram_addr == (DRAM_MAX_ADDR-1));

endmodule
