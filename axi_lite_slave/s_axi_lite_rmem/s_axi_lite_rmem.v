`default_nettype none
`include "bram_infer.v"
/* a bram interface with axi lite slave
*/

module s_axi_lite_rmem #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 8
) (
    input wire S_AXI_ACLK,
    input wire S_AXI_ARESETn,
    //address write channel
    input wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input wire [2:0] S_AXI_AWPROT,
    input wire S_AXI_AWVALID,
    output wire S_AXI_AWREADY,
    //write data channel
    input wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input wire [C_S_AXI_DATA_WIDTH/8-1:0] S_AXI_WSTRB,
    input wire S_AXI_WVALID,
    output wire S_AXI_WREADY,
    //write response channel
    output wire [1:0] S_AXI_BRESP,
    output wire S_AXI_BVALID,
    input wire S_AXI_BREADY,
    //read address channel 
    input wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input wire S_AXI_ARVALID,
    output wire S_AXI_ARREADY,
    input wire [2:0] S_AXI_ARPROT,
    //read data channel
    output wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output wire [1:0] S_AXI_RRESP,
    output wire S_AXI_RVALID,
    input wire S_AXI_RREADY,

    //external signals
    input wire [C_S_AXI_ADDR_WIDTH-3:0] waddr,
    input wire [C_S_AXI_DATA_WIDTH-1:0] win,
    input wire w_en

);
//axi registers

reg axi_awready=1;
reg axi_wready=1;
reg axi_bvalid=0;
reg axi_arready=0;
//reg [C_S_AXI_DATA_WIDTH-1:0] axi_rdata=0;
reg axi_rvalid=0;

localparam integer ADDR_LSB=2;
localparam integer AW = C_S_AXI_ADDR_WIDTH-2; //it byte addressing
localparam integer DW = C_S_AXI_DATA_WIDTH;

//reg [DW-1:0] slv_mem [0:63]; //why put them backwards?

//synchronizer..(A fifo would be best solution)
reg [DW-1:0] din=0, din1=0;
reg [C_S_AXI_ADDR_WIDTH-1:0] wadd=0,wadd1=0;
reg wen=0, wen1=0;
always@(posedge S_AXI_ACLK)begin
    din <= win;     din1 <= din;
    wadd <= waddr;  wadd1 <= wadd;
    wen <= w_en;    wen1 <= wen;
end

wire valid_read_req, read_resp_stall;


bram_infer #(
    .N_ADDR(2**AW),
    .DATA_WIDTH(DW)
)bram_infer_inst (
    .clk(S_AXI_ACLK),
    .wen(wen1),
    //.ren(S_AXI_ARREADY&S_AXI_ARVALID),
    //.ren(1'b1),
    .ren(!read_resp_stall && valid_read_req),
    .wadd(wadd1),
    .radd(rd_addr[C_S_AXI_ADDR_WIDTH-1:ADDR_LSB]),
    .win(din1),
    .wout(S_AXI_RDATA)
);

//delay in the rvalid signal to match the bram latency
reg [1:0]axi_rvalid_d=0;
always@(posedge S_AXI_ACLK)begin
    axi_rvalid_d <= {axi_rvalid_d[0], axi_rvalid};
end

//asign each output with it correspondent register
assign S_AXI_AWREADY = axi_awready;
assign S_AXI_WREADY = axi_wready;
assign S_AXI_BRESP = 2'b00; //always ok
assign S_AXI_BVALID = axi_bvalid;
assign S_AXI_ARREADY = axi_arready;
//assign S_AXI_RDATA = axi_rdata;
assign S_AXI_RRESP = 2'b00;
assign S_AXI_RVALID = axi_rvalid_d[1];

//read side, the idea is to use a buffer to been able to handle 
//two consecutives requests, if a third is issue and none of the
//two has been terminated the arready is lowered

//flags
//wire valid_read_req, read_resp_stall;
assign valid_read_req = S_AXI_ARVALID || !S_AXI_ARREADY;
assign read_resp_stall = S_AXI_RVALID && !S_AXI_RREADY;

always@(posedge S_AXI_ACLK)begin
    if(!S_AXI_ARESETn)
        axi_rvalid <= 0;
    else if(read_resp_stall)begin
        //we have to keep it up until the recv is ready
        axi_rvalid <= 1;
    end
    else if(valid_read_req)
        axi_rvalid <=1;
    else 
        axi_rvalid <= 0;
end

reg [C_S_AXI_ADDR_WIDTH-1:0] pre_raddr=0, rd_addr=0;

always@(posedge S_AXI_ACLK)begin
    if(S_AXI_ARREADY)
        pre_raddr <= S_AXI_ARADDR;
end

always@(*)begin
    if(!axi_arready)
        rd_addr = pre_raddr;
    else
        rd_addr = S_AXI_ARADDR;
end

//read the data if i am not stalled
/*
always@(posedge S_AXI_ACLK)begin
    if(!read_resp_stall && valid_read_req)
        axi_rdata <= slv_mem[rd_addr[AW+ADDR_LSB-1:ADDR_LSB]];
end
*/
//read addr ready signal
always@(posedge S_AXI_ACLK)begin
    if(!S_AXI_ARESETn)
        axi_arready <= 1;
    else if(read_resp_stall) begin
        //if stall i should wait until the buffer is free
        axi_arready <= !valid_read_req;
    end
    else
        axi_arready<=1;
end

//write side
//same idea
/*
reg [C_S_AXI_ADDR_WIDTH-1:0] pre_waddr=0, waddr=0;
reg [C_S_AXI_DATA_WIDTH-1:0] pre_wdata=0, wdata=0;
reg [C_S_AXI_DATA_WIDTH/8-1:0] pre_wstrb=0, wstrb=0;

wire valid_write_addr, valid_write_data, write_resp_stall;

assign valid_write_addr = S_AXI_AWVALID || !axi_awready;
assign valid_write_data = S_AXI_WVALID || !axi_wready;
assign write_resp_stall = S_AXI_BVALID && !S_AXI_BREADY;


//write ready signal
always@(posedge S_AXI_ACLK)begin
    if(!S_AXI_ARESETn)
        axi_awready<= 1;
    else if(write_resp_stall)begin
        //if the buffer is full we have to lower it
        axi_awready <= !valid_write_addr;
    end
    else if(valid_write_data) begin
        //write data is available and we have space in the buffer
        axi_awready <= 1;
    end
    else
        axi_awready <= axi_awready && !S_AXI_AWVALID;
end

//write data ready signal
always@(posedge S_AXI_ACLK)begin
    if(!S_AXI_ARESETn)
        axi_wready <= 1;
    else if(write_resp_stall) begin
        //there is something in the buffer, we need to wait
        axi_wready <= !valid_write_data;
    end
    else if(valid_write_addr)begin
        //the buffer is empty
        axi_wready <= 1;
    end
    else begin
        //default case
        axi_wready <= axi_wready && !S_AXI_WVALID; //? i dont get it
    end
end

//buffering the addr
always@(posedge S_AXI_ACLK)begin
    if(S_AXI_AWREADY)
        pre_waddr <= S_AXI_AWADDR;
end
//buffering the data
always@(posedge S_AXI_ACLK)begin
    if(S_AXI_WREADY)begin
        pre_wdata <= S_AXI_WDATA;
        pre_wstrb <= S_AXI_WSTRB;
    end
end

always@(*)begin
    if(!axi_awready)
        waddr = pre_waddr;
    else
        waddr = S_AXI_AWADDR;

end


always@(*)begin
    if(!axi_wready) begin
        //read write data from the buffer
        wstrb = pre_wstrb;
        wdata = pre_wdata;
    end
    else begin
        wstrb = S_AXI_WSTRB;
        wdata = S_AXI_WDATA;
    end
end


//write the data
always@(posedge S_AXI_ACLK)begin
    if(!write_resp_stall && valid_write_addr &&valid_write_data) begin
        if(wstrb[0])
            slv_mem[waddr[AW+ADDR_LSB-1:ADDR_LSB]][7:0]<= wdata[7:0];
        if(wstrb[1])
            slv_mem[waddr[AW+ADDR_LSB-1:ADDR_LSB]][15:8]<=wdata[15:8];
        if(wstrb[2])
            slv_mem[waddr[AW+ADDR_LSB-1:ADDR_LSB]][23:16]<=wdata[23:16];
        if(wstrb[3])
            slv_mem[waddr[AW+ADDR_LSB-1:ADDR_LSB]][31:24]<=wdata[31:24];
    end
end

//write response valid signal
always@(posedge S_AXI_ACLK)begin
    if(!S_AXI_ARESETn)
        axi_bvalid <= 0;
    else if (valid_write_addr && valid_write_data)begin
        //here everything works
        axi_bvalid <= 1;
    end
    else if(S_AXI_BREADY)
        axi_bvalid <= 0;
end
*/
//there are the protect signals.. here we dont care about them
endmodule 
