`default_nettype none
//`include "bram_infer.v"

module fifo_sync #(
    parameter DIN_WIDTH = 16,
    parameter FIFO_DEPTH = 64
) (
    input wire clk,
    input wire rst,
    
    input wire [DIN_WIDTH-1:0] wdata,
    input wire w_valid,

    output wire empty, full,
    output wire [DIN_WIDTH-1:0] rdata,
    output wire r_valid,
    input wire read_req 
    //if the fifo is not empty the answer will be in the next cycle
);



//write logic
wire wen = w_valid & ~full;
reg [$clog2(FIFO_DEPTH):0] waddr=0, raddr=0;
always@(posedge clk)begin
    if(rst)
        waddr <=0;
    else if(wen)
        waddr <= waddr+1;
    else
        waddr <= waddr;
end


assign empty = (waddr==raddr);
assign full = (waddr[$clog2(FIFO_DEPTH)] != raddr[$clog2(FIFO_DEPTH)]) && 
    (waddr[$clog2(FIFO_DEPTH)-1:0]==raddr[$clog2(FIFO_DEPTH)-1:0]);


//read data
wire ren = read_req & ~empty;
always@(posedge clk)begin
    if(rst)
        raddr <= 0;
    else if(ren)
        raddr <= raddr+1;
    else
        raddr <= raddr;
end

bram_infer #(
    .N_ADDR(FIFO_DEPTH),
    .DATA_WIDTH(DIN_WIDTH)
) bram_infer_inst (
    .clk(clk),
    .wen(wen),
    .ren(ren),
    .wadd(waddr[$clog2(FIFO_DEPTH)-1:0]),
    .radd(raddr[$clog2(FIFO_DEPTH)-1:0]),
    .win(wdata),
    .wout(rdata)
);

reg r_valid_r=0;
always@(posedge clk)
    r_valid_r <= ren;

assign r_valid = r_valid_r;

endmodule 
