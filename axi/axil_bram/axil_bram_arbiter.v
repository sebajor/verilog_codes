`default_nettype none 

module axil_bram_arbiter #(
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
    input wire s_axil_rready,

    //bram interface
    output wire [ADDR_WIDTH-1:0] bram_addr,
    input wire [DATA_WIDTH-1:0] bram_dout,
    output wire [DATA_WIDTH-1:0] bram_din,
    output wire bram_we
);

assign s_axil_rresp = 2'b00;
assign s_axil_bresp = 2'b00;

//read side is going to have preference
wire skraddr_valid, skraddr_rdy;
wire [ADDR_WIDTH-1:0] skraddr;

wire skrdata_valid, skrdata_rdy;
wire [DATA_WIDTH-1:0] skrdata;


wire skwaddr_valid, skwaddr_rdy;
wire [ADDR_WIDTH-1:0] skwaddr;

wire skwdata_valid, skwdata_rdy;
wire [DATA_WIDTH-1:0] skwdata;

//flags
wire read_stall = s_axil_rvalid && ~s_axil_rready;
wire write_stall = s_axil_bvalid && ~s_axil_bready;


//skidbuffer read address
skid_buffer #(
    .DIN_WIDTH(ADDR_WIDTH)
)skid_buffer_raddr (
    .clk(axi_clock),
    .rst(rst),
    .din(s_axil_araddr[ADDR_WIDTH+1:2]),
    .din_valid(s_axil_arvalid), 
    .din_ready(s_axil_arready), 
    .dout_valid(skraddr_valid), 
    .dout_ready(skraddr_rdy), 
    .dout(skraddr)
);


//skraddr_rdy = sk_raddr_val & ~(read_stall)

//skidbuffer write address

skid_buffer #(
    .DIN_WIDTH(ADDR_WIDTH)
)skid_buffer_waddr (
    .clk(axi_clock),
    .rst(rst),
    .din(s_axil_awaddr[ADDR_WIDTH+1:2]),
    .din_valid(s_axil_awvalid), 
    .din_ready(s_axil_awready), 
    .dout_valid(skwaddr_valid), 
    .dout_ready(skwaddr_rdy), 
    .dout(skwaddr)
);


//skid buffer write data
skid_buffer #(
    .DIN_WIDTH(DATA_WIDTH)
) skid_buffer_wdata (
    .clk(axi_clock),
    .rst(rst),
    .din(s_axil_wdata),
    .din_valid(s_axil_wvalid), 
    .din_ready(s_axil_wready), 
    .dout_valid(skwdata_valid), 
    .dout_ready(skwdata_rdy), 
    .dout(skwdata)
);


//arbiter
//wire read_busy = read_stall | skraddr_valid;
//wire write_busy = write_stall | (skwaddr_valid & skwdata_valid);

reg read_busy =0;
reg write_busy =0;

always@(posedge axi_clock)begin
    if(rst)
        read_busy <= 0;
    else if(skraddr_valid & skraddr_rdy)
        read_busy <= 1;
    else if(read_stall)
        read_busy <= 1;
    else if(s_axil_rready & s_axil_rvalid)
        read_busy <=0;
end

always@(posedge axi_clock)begin
    if(rst)
        write_busy <=0;
    else if(skwaddr_valid & skwaddr_rdy)
        write_busy <= 1;
    else if(write_stall)
        write_busy <=1;
    else if(s_axil_bready & s_axil_bvalid)
        write_busy <=0;
end

//check!
//assign skraddr_rdy = skraddr_valid & ~(read_busy | write_busy | read_stall);
//assign skwaddr_rdy = skwaddr_valid & ~(read_busy | write_busy | read_stall | write_stall);
//assign skwdata_rdy = skwdata_valid & ~(read_busy | write_busy | read_stall | write_stall );

assign skraddr_rdy = skraddr_valid & ~(write_stall | read_stall);
assign skwaddr_rdy = skwaddr_valid & ~(skraddr_valid | read_stall | write_stall);
assign skwdata_rdy = skwdata_valid & ~(skraddr_valid | read_stall | write_stall );

//
reg [ADDR_WIDTH-1:0] bram_addr_r=0;
always@(*)begin
    if(skwaddr_valid & skwaddr_rdy)
        bram_addr_r = skwaddr;
    else
        bram_addr_r = skraddr;
end

assign bram_addr = bram_addr_r;
assign bram_din = skwdata;
assign bram_we = (skwaddr_valid & skwaddr_rdy);


//read resp 
reg axi_read_valid=0;
always@(posedge axi_clock)begin
    if(rst)
        axi_read_valid <=0;
    else if(skraddr_rdy)
        axi_read_valid <=1;
    else if(s_axil_rready)
        axi_read_valid <=0;
end
assign skrdata_valid = axi_read_valid;

skid_buffer #(
    .DIN_WIDTH(DATA_WIDTH)
) skid_buffer_rdata (
    .clk(axi_clock),
    .rst(rst),
    .din(bram_dout),
    .din_valid(skrdata_valid), 
    .din_ready(skrdata_rdy), 
    .dout_valid(s_axil_rvalid), 
    .dout_ready(s_axil_rready), 
    .dout(s_axil_rdata)
);


//write response, in this case always ok
reg axi_bvalid =0;
assign s_axil_bvalid = axi_bvalid;
always@(posedge axi_clock)begin
    if(rst)
        axi_bvalid <= 0;
    else if(skwaddr_rdy)
        axi_bvalid <=1;
    else if(s_axil_bready)
        axi_bvalid <=0;
end




endmodule
