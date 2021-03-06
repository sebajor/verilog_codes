`default_nettype none

//axi master, doesnt handle burst transactions

module axi_lite_master #(
    parameter AXI_ADDR_WIDHT = 32,  //bit
    parameter AXI_DATA_WIDTH = 32  //bit
) (
    input wire M_AXI_ACLK,
    input wire M_AXI_ARESETN,

    //write address channel
    output wire [AXI_ADDR_WIDHT-1:0] M_AXI_AWADDR,
    //protection type
    output wire [2:0] M_AXI_AWPROT,
    output wire M_AXI_AWVALID,
    input wire M_AXI_AWREADY,

    //write channel
    output wire [AXI_DATA_WIDTH-1:0] M_AXI_WDATA,
    output wire [AXI_DATA_WIDTH/8-1:0] M_AXI_WSTRB,
    output wire M_AXI_WVALID,
    input wire M_AXI_WREADY,

    //response channel
    input wire [1:0] M_AXI_BRESP,
    input wire M_AXI_BVALID,
    output wire M_AXI_BREADY,

    //read address channel
    output wire [AXI_ADDR_WIDHT-1:0] M_AXI_ARADDR,
    output wire [2:0] M_AXI_ARPROT,
    output wire M_AXI_ARVALID,
    input wire M_AXI_ARREADY,

    //read data channel 
    input wire [AXI_DATA_WIDTH-1:0] M_AXI_RDATA,
    input wire  M_AXI_RVALID,
    output wire M_AXI_RREADY,
    input wire [1:0] M_AXI_RRESP,

    //custom signals
    input wire mwr_valid,
    input wire [AXI_DATA_WIDTH-1:0] mwr_data,
    input wire [AXI_ADDR_WIDHT-1:0] mwr_addr,
    output wire mwr_ready,
    output wire mwr_error,

    input wire mrd_addr_valid,
    input wire [AXI_ADDR_WIDHT-1:0] mrd_addr,
    output wire mrd_addr_ready,

    output wire [AXI_DATA_WIDTH-1:0] mrd_data,
    output wire mrd_data_valid,
    input wire mrd_data_ready,
    output wire mrd_error
);


reg axi_awvalid=0;
reg axi_wvalid=0;
reg axi_bready=1;
reg axi_arvalid=0;
reg axi_rready=1;
reg [AXI_DATA_WIDTH-1:0] axi_wdata=0, axi_rdata=0;
reg [AXI_ADDR_WIDHT-1:0] axi_awaddr=0, axi_araddr=0;


assign M_AXI_AWVALID = axi_awvalid;
assign M_AXI_BREADY = axi_bready;
assign M_AXI_WVALID = axi_wvalid;
assign M_AXI_ARVALID = axi_arvalid;
assign M_AXI_RREADY = axi_rready;
assign M_AXI_AWADDR = axi_awaddr;
assign M_AXI_ARADDR = axi_araddr;

//mrd and mwr regs
reg mwr_ready_r=0;
assign mwr_ready = mwr_ready_r;

//write address channel
assign M_AXI_AWPROT = 3'b000;   
assign M_AXI_WSTRB = 4'b1111;


//first we receive the data from the uart
reg write = 0;      //writing flag
always@(posedge M_AXI_ACLK)begin
    if(write)begin
        mwr_ready_r <=0;
        //end of writing condition
        if(M_AXI_BVALID && axi_bready)
            write <= 0;
    end
    else begin
        mwr_ready_r <= 1;
        if(mwr_valid)begin
            
            write <= 1;
            axi_wdata <= mwr_data;
            axi_awaddr <= {mwr_addr[AXI_ADDR_WIDHT-1:1], 2'b00};
        end 
    end
end


//start transaction
always@(posedge M_AXI_ACLK)begin
    if(~M_AXI_ARESETN)begin
        axi_awvalid <= 1'b0;
    end
    else if(M_AXI_AWREADY && axi_awvalid)
        axi_awvalid <= 1'b0;
    else if(mwr_valid)
        axi_awvalid <= 1'b1;
    else
        axi_awvalid <= axi_awvalid;
end


//write data channel 
always@(posedge M_AXI_ACLK)begin
    if(~M_AXI_ARESETN)
        axi_wvalid <= 1'b0;
    else if(M_AXI_WREADY && axi_wvalid)
        axi_wvalid <= 1'b0;
    else if(mwr_valid)
        axi_wvalid <= 1'b1;
    else 
        axi_wvalid <= axi_wvalid;
end

//write response channel
always@(posedge M_AXI_ACLK)begin
    if(M_AXI_ARESETN)
        axi_bready <= 1'b0;
    else
        axi_bready <= 1'b1;
end

assign mwr_error = axi_bready & M_AXI_BVALID & M_AXI_BRESP[1];


//read address channel
reg mrd_addr_ready_r=0;
assign mrd_addr_ready = mrd_addr_ready_r;


reg read = 0;      //reading flag
always@(posedge M_AXI_ACLK)begin
    if(read)begin
        mrd_addr_ready_r <=0;
        //end of writing condition
        if(M_AXI_RVALID && axi_rready)
            read <= 0;
    end
    else begin
        mrd_addr_ready_r <= 1;
        if(mrd_addr_valid)begin
            mrd_addr_ready_r <=0;
            read <= 1;
            axi_araddr <= {mrd_addr[AXI_ADDR_WIDHT-1:1], 2'b00};
        end 
    end
end



always@(posedge M_AXI_ACLK)begin
    if(~M_AXI_ARESETN)
        axi_arvalid <= 1'b0;
    else if(M_AXI_ARREADY && axi_arvalid)
        axi_arvalid <= 1'b0;
    else if(mrd_addr_valid)
        axi_arvalid <= 1'b1;
    else
        axi_arvalid <= axi_arvalid;
end

//read data channel
always@(posedge M_AXI_ACLK)begin
    if(~M_AXI_ARESETN)
        axi_rready <= 1'b0;
    else 
        axi_rready <= 1'b1;
end

assign mrd_error = axi_rready & M_AXI_RVALID & M_AXI_RRESP[1];

always@(posedge M_AXI_ACLK)begin
    if(axi_rready & M_AXI_RVALID)
        axi_rdata <= M_AXI_RDATA;
    else
        axi_rdata <= axi_rdata;
end

//axi interface for mrd data
reg mrd_data_valid_r =0;
always@(posedge M_AXI_ACLK)begin
    if(axi_rready & M_AXI_RVALID)
        mrd_data_valid_r <= 1'b1;
    else if(mrd_data_ready & mrd_data_valid_r)
        mrd_data_valid_r <= 1'b0;
    else
        mrd_data_valid_r <= mrd_data_valid_r;
end



endmodule
