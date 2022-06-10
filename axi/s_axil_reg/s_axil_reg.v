`default_nettype none

//if there are no external interface for the registers the compiler 
//uses block rams to create the axi_reg, if there is an external reg
//it uses luts

module s_axil_reg #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 10
) (
    input wire axi_clock, 
    input wire rst, 
    //write address channel
    input wire [ADDR_WIDTH+1:0] s_axil_awaddr,
    input wire [2:0] s_axil_awprot,
    input wire s_axil_awvalid,
    output wire s_axil_awready,
    //write data channel
    input wire [DATA_WIDTH-1:0] s_axil_wdata,
    input wire [DATA_WIDTH/8-1:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output wire s_axil_wready,
    //write response channel 
    output wire [1:0] s_axil_bresp,
    output wire s_axil_bvalid,
    input wire s_axil_bready,
    //read address channel
    input wire [ADDR_WIDTH+1:0] s_axil_araddr,
    input wire s_axil_arvalid,
    output wire s_axil_arready,
    input wire [2:0] s_axil_arprot,
    //read data channel
    output wire [DATA_WIDTH-1:0] s_axil_rdata,
    output wire [1:0] s_axil_rresp,
    output wire s_axil_rvalid,
    input wire s_axil_rready
);

//axi registers
reg axi_awready=1;
reg axi_wready =1;
reg axi_bvalid =0;
reg axi_arready=1;
reg [DATA_WIDTH-1:0] axi_rdata=0;
reg axi_rvalid=0;


//registers,
//check how this is implemented

//(* ram_style = "distributed" *)  //directive to xst
reg [DATA_WIDTH-1:0] axi_reg [2**ADDR_WIDTH-1:0];
integer i;
initial begin
    for(i=0; i<2**ADDR_WIDTH-1; i=i+1)
        axi_reg[i] = 0;
end

//assign each ouptut with its register version
assign s_axil_awready = axi_awready;
assign s_axil_wready = axi_wready;
assign s_axil_bresp = 2'b00;    //ok
assign s_axil_arready = axi_arready;
assign s_axil_rdata = axi_rdata;
assign s_axil_rresp = 2'b00;
assign s_axil_rvalid = axi_rvalid;
assign s_axil_bvalid = axi_bvalid;

//read side. The idea of this implementation is to use a buufer to handle
//consecutives request. If there is a request and the previous one
//is stalled the arready is lowered.

//flags 
wire valid_read_req, read_resp_stall;
assign valid_read_req = s_axil_arvalid || !s_axil_arready;  //
assign read_resp_stall = s_axil_rvalid && ~s_axil_rready;


always@(posedge axi_clock)begin
    if(rst)
        axi_rvalid <=0;
    else if(read_resp_stall)begin
        //we keep the output in one until is accepted
        axi_rvalid <= 1;
    end
    else if(valid_read_req)
        axi_rvalid <=1;
    else
        axi_rvalid <=0;
end

reg [ADDR_WIDTH-1:0] pre_raddr=0, rd_addr=0;
always@(posedge axi_clock)begin
    if(s_axil_arready)
        pre_raddr <= s_axil_araddr[ADDR_WIDTH+1:2];
end

always@(*)begin
    if(!axi_arready)
        rd_addr = pre_raddr;
    else
        rd_addr = s_axil_araddr[ADDR_WIDTH+1:2];
end

//read the data if i am not stalled
always@(posedge axi_clock)begin
    if(!read_resp_stall & valid_read_req)
        axi_rdata <= axi_reg[rd_addr];
end

//read addr ready signal
always@(posedge axi_clock)begin
    if(rst)
        axi_arready <= 1;
    else if(read_resp_stall)begin
        //if stalled, wait until the buffer is free
        axi_arready <= ~valid_read_req;
    end
    else
        axi_arready <= 1;
end

//write side. Follows the same idea

reg [ADDR_WIDTH-1:0] pre_waddr=0, waddr=0;
reg [DATA_WIDTH-1:0] pre_wdata=0, wdata=0;
reg [DATA_WIDTH/8-1:0] pre_wstrb=0, wstrb=0;

wire valid_write_addr, valid_write_data, write_resp_stall;

assign valid_write_addr = s_axil_awvalid || ~axi_awready;
assign valid_write_data = s_axil_wvalid || ~axi_wready;
assign write_resp_stall = s_axil_bvalid && ~s_axil_bready;


//write addr ready signal
always@(posedge axi_clock)begin
    if(rst)
        axi_awready <= 1;
    else if(write_resp_stall)begin
        axi_awready <= !valid_write_addr;
    end
    else if(valid_write_data)begin
        axi_awready <= 1;
    end
    else begin
        //axi_awready <= axi_awready &~s_axil_awvalid;
        axi_awready <= ~valid_write_addr;
    end
end

//write data ready signal
always@(posedge axi_clock)begin
    if(rst)
        axi_wready <= 1;
    else if(write_resp_stall)
        axi_wready <= !valid_write_data;
    else if(valid_write_data)
        axi_wready <= 1;
    else begin
        //axi_wready <= axi_wready & ~s_axil_wvalid;
        axi_wready <= ~valid_write_data;
    end
end


//buffer the addr
always@(posedge axi_clock)begin
    if(s_axil_awready)
        pre_waddr <= s_axil_awaddr[ADDR_WIDTH+1:2];
end

always@(posedge axi_clock)begin
    if(s_axil_wready)begin
        pre_wdata <= s_axil_wdata;
        pre_wstrb <= s_axil_wstrb; 
    end
end

always@(*)begin
    if(~axi_awready)
        waddr = pre_waddr;
    else
        waddr = s_axil_awaddr[ADDR_WIDTH+1:2];
end

always@(*)begin
    if(~axi_wready)begin
        wdata = pre_wdata;
        wstrb = pre_wstrb;
    end
    else begin
        wdata = s_axil_wdata;
        wstrb = s_axil_wstrb;
    end
end


//write the data into the registers
//if you want to write into a register you have to add a condition here
always@(posedge axi_clock)begin
    if(~write_resp_stall & valid_write_addr & valid_write_data) begin
        if(wstrb[0])
            axi_reg[waddr][7:0] <= wdata[7:0];
        if(wstrb[1])
            axi_reg[waddr][15:8] <= wdata[15:8];
        if(wstrb[2])
            axi_reg[waddr][23:16] <= wdata[23:16];
        if(wstrb[3])
            axi_reg[waddr][31:24] <= wdata[31:24];
    end
end

//write response valid signal
always@(posedge axi_clock)begin
    if(rst)
        axi_bvalid <= 0;
    else if(valid_write_addr && valid_write_data)
        axi_bvalid <= 1;
    else if(s_axil_bready)
        axi_bvalid<=0;
end

//you could make visible some register creating an output port


endmodule
