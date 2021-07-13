`default_nettype none
`include "skid_buffer.v"
`include "async_true_dual_ram.v"

module s_axil_ram_rd #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 10
) (
    input wire axi_clock,
    input wire rst,
    //address read channel 
    input wire [ADDR_WIDTH+1:0] s_axil_araddr,
    input wire                  s_axil_arvalid,
    output wire                 s_axil_arready,
    input wire [2:0]            s_axil_arprot,
    //read data channel
    output wire [DATA_WIDTH-1:0] s_axil_rdata,
    output wire [1:0]            s_axil_rresp,
    output wire                  s_axil_rvalid,
    input wire                   s_axil_rready,
    //fpga interface
    input wire fpga_clk,
    input wire [ADDR_WIDTH-1:0] bram_addr,
    input wire                  we,
    input wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout
);

assign s_axil_rresp = 2'b00;


wire axil_read_ready;
reg axil_read_valid=0;
wire [ADDR_WIDTH-1:0] arskd_addr;
reg [DATA_WIDTH-1:0] axil_raed_data=0;
reg axil_read_valid=0;

wire arskd_valid;

skid_buffer #(
    .DIN_WIDTH(ADDR_WIDTH)
) skid_raddr(
    .clk(axi_clock),
    .rst(rst),
    .din(s_axil_araddr[ADDR_WIDTH+1:2]),
    .din_valid(s_axil_arvalid), 
    .din_ready(s_axil_arready), 
    .dout_valid(arskd_valid), 
    .dout_ready(axil_read_ready), 
    .dout(arskd_addr)
);

assign axil_read_ready = arskd_valid && (!axil_read_valid || s_axil_rready);


always@(posedge axi_clock)begin
    if(rst)
        axil_read_valid <= 0;
    else if(axil_read_ready)
        axil_read_valid <= 1;
    else if(s_axil_rready)
        axil_read_valid <= 0;
end

assign s_axil_rvalid = axil_read_valid;
assign s_axil_rresp = 2'b00;






wire sk_raddr_val;
wire [ADDR_WIDTH-1:0] sk_raddr; 

wire sk_rdata_rdy;
//reg sk_araddr_rdy=0;
wire sk_araddr_rdy;

assign sk_araddr_rdy = sk_raddr_val & s_axil_rready;//(!s_axil_RVALID || s_axil_RREADY);


skid_buffer #(
    .DIN_WIDTH(ADDR_WIDTH)
) skid_raddr(
    .clk(axi_clock),
    .rst(rst),
    .din(s_axil_araddr[ADDR_WIDTH+1:2]),
    .din_valid(s_axil_arvalid), 
    .din_ready(s_axil_arready), 
    .dout_valid(sk_raddr_val), 
    .dout_ready(sk_araddr_rdy), 
    .dout(sk_raddr)
);

reg axi_read_val=0;
always@(posedge axi_clock)begin
    if(rst)
        axi_read_val<=0;
    //else if(sk_araddr_rdy)
    else if(sk_raddr_val)
        axi_read_val<=1;
    else if(s_axil_rready)
        axi_read_val <= 0;
end

assign s_axil_rvalid= axi_read_val;



wire [DATA_WIDTH-1:0] axi_rdata;
assign s_axil_rdata = axi_rdata;

async_true_dual_ram #(
    .RAM_WIDTH(DATA_WIDTH),
    .RAM_DEPTH(2**ADDR_WIDTH)
) ram_inst (
  .clkb(axi_clock),
  .addrb(sk_raddr), 
  .dinb(),
  .doutb(axi_rdata),
  .web(1'b0),
  .enb(1'b1),
  .rstb(1'b0),
  .clka(fpga_clk),
  .addra(bram_addr),
  .dina(din),
  .douta(dout),
  .ena(1'b1),
  .wea(we),
  .rsta(1'b0)
);


endmodule


