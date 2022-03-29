`default_nettype none
`include "rtl/sync_simple_dual_ram.v"
`inlcude "../skid_buffer/skid_buffer.v"

module axis_fifo_sync #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 4     //2**DEPTH
) (
    input wire clk,
    input wire rst,
    //write interface
    input wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input wire  s_axis_tvalid,
    output wire s_axis_tready,
    
    //read interface
    output wire [DATA_WIDTH-1:0] m_axis_tdata,
    output wire m_axis_tvalid,
    input wire  m_axis_tready
);

wire [DATA_WIDTH-1:0] write_data;
wire write_valid, wire write_ready;
    
skid_buffer #(
    .DIN_WIDTH(DATA_WIDTH)
) skid_buffer_write (
    .clk(clk),
    .rst(rst),
    .din(s_axis_tdata),
    .din_valid(s_axis_tdata), 
    .din_ready(s_axis_tready), 
    .dout_valid(write_valid), 
    .dout_ready(write_ready), 
    .dout(write_data)
);


wire fifo_full, fifo_empty;
reg [DEPTH:0] waddr=0, raddr=0;
always@(posedge clk)begin
    if(rst)
        waddr <=0;
    else if(write_valid & write_ready)
        waddr <= waddr+1;
end

assign write_ready = ~full;


wire [DATA_WIDTH-1:0] rdata;

sync_simple_dual_ram #(
    .RAM_WIDTH(DATA_WIDTH),
    .RAM_DEPTH(2**ADDR_WIDTH),
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
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

//read stall 
wire read_stall = m_axis_tvalid



endmodule
