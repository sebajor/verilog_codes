`default_nettype none

/*
*   Synchronous FIFO.
*   The write only occurs when ~full & w_valid in the same clock cycle
*   
*   This module takes 2 cycles to anwser a read request. It doesnt support
*   backpreassure. 
*/


module fifo_sync #(
    parameter DIN_WIDTH = 16,
    parameter FIFO_DEPTH = 3, //address = 2**FIFO_DEPTH
    parameter RAM_PERFORMANCE = "HIGH_PERFORMANCE"
) (
    input wire clk,
    input wire rst,

    input wire [DIN_WIDTH-1:0] wdata,
    input wire w_valid,

    output wire full, empty,
    output wire [DIN_WIDTH-1:0] rdata,
    output wire r_valid,
    input wire read_req
);
//write side
wire wen = w_valid & ~full;
reg [FIFO_DEPTH:0] waddr=0, raddr=0;
always@(posedge clk)begin    
    if(rst)
        waddr <=0;
    else if(wen)
        waddr <= waddr+1;
end

assign empty = (waddr == raddr);
assign full = (waddr[FIFO_DEPTH] != raddr[FIFO_DEPTH]) &
            (waddr[FIFO_DEPTH-1:0] == raddr[FIFO_DEPTH-1:0]);

//read side
wire ren = read_req & ~empty;
always@(posedge clk)begin
    if(rst)
        raddr <= 0;
    else if(ren)
        raddr <= raddr+1;
end

sync_simple_dual_ram #(
    .RAM_WIDTH(DIN_WIDTH),
    .RAM_DEPTH(2**FIFO_DEPTH),
    .RAM_PERFORMANCE(RAM_PERFORMANCE),
    .INIT_FILE("")
) ram_inst (
    .addra(waddr[FIFO_DEPTH-1:0]),
    .addrb(raddr[FIFO_DEPTH-1:0]),
    .dina(wdata),
    .clka(clk),
    .wea(wen),
    .enb(1'b1),
    .rstb(1'b0),
    .regceb(1'b1),
    .doutb(rdata)
);

reg [1:0] rvalid_r=0;
always@(posedge clk)begin
    if(rst)
        rvalid_r <=0;
    else
        rvalid_r <= {rvalid_r[0], ren};
end

assign r_valid = rvalid_r[1];

endmodule
