`default_nettype none

module axis_fifo_sync #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 4     //2**DEPTH
) (
    input wire clk,
    input wire rst,
    //write interface
    input wire [DATA_WIDTH-1:0]  write_tdata,
    input wire  write_tvalid,
    output wire write_tready,
    
    //read interface
    output wire [DATA_WIDTH-1:0] read_tdata,
    output wire read_tvalid,
    input wire  read_tready

);


wire [DATA_WIDTH-1:0] write_data;
wire write_valid, write_ready;
    
skid_buffer #(
    .DIN_WIDTH(DATA_WIDTH)
) skid_buffer_write (
    .clk(clk),
    .rst(rst),
    .din(write_tdata),
    .din_valid(write_tvalid), 
    .din_ready(write_tready), 
    .dout_valid(write_valid), 
    .dout_ready(write_ready), 
    .dout(write_data)
);


wire fifo_full, fifo_empty;
reg [ADDR_WIDTH:0] waddr=0, raddr=0;
always@(posedge clk)begin
    if(rst)
        waddr <=0;
    else if(write_valid & write_ready)
        waddr <= waddr+1;
end

assign fifo_empty = (waddr == raddr);
assign fifo_full = (waddr[ADDR_WIDTH] != raddr[ADDR_WIDTH]) &
            (waddr[ADDR_WIDTH-1:0] == raddr[ADDR_WIDTH-1:0]);

assign write_ready = ~fifo_full;

wire [DATA_WIDTH-1:0] rdata;

sync_simple_dual_ram #(
    .RAM_WIDTH(DATA_WIDTH),
    .RAM_DEPTH(2**ADDR_WIDTH),
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
    .INIT_FILE("")
) ram_inst (
    .addra(waddr[ADDR_WIDTH-1:0]),
    .addrb(raddr[ADDR_WIDTH-1:0]),
    .dina(write_data),
    .clka(clk),
    .wea(write_valid),
    .enb(1'b1),
    .rstb(1'b0),
    .regceb(1'b1),
    .doutb(rdata)
);
//like it takes two cycles to complete a read we are going to cascade two
// skid buffers

wire sk_valid, sk_ready;
wire [DATA_WIDTH-1:0] sk_data;
wire read_ready;
reg [1:0] read_valid=0;

always@(posedge clk)begin
    if(rst)begin
        raddr <=0;
    end
    else if((read_ready & ~fifo_empty) & ~read_stall)
        raddr <= raddr+1;
end

always@(posedge clk)begin
    if(rst)
        read_valid <=0;
    else
        read_valid <= {read_valid[0], (read_ready & ~fifo_empty)};
end

wire read_stall = ~(read_ready);
reg stall_flag =0;
reg [DATA_WIDTH-1:0] rdata_r=0;
always@(posedge clk)begin
    if(read_stall)begin
        rdata_r <= rdata;
        stall_flag <= 1;
    end
    else
        stall_flag <= 0;
end

reg [DATA_WIDTH-1:0] dout=0;
always@(*)begin
    if(stall_flag)
        dout = rdata_r;
    else
        dout = rdata; 
end

skid_buffer #(
    .DIN_WIDTH(DATA_WIDTH)
) skid_buffer_read0 (
    .clk(clk),
    .rst(rst),
    .din(dout),
    .din_valid(read_valid[1] | stall_flag), 
    .din_ready(read_ready), 
    .dout_valid(read_tvalid),//(sk_valid), 
    .dout_ready(read_tready),//(sk_ready), 
    .dout(read_tdata)//(sk_data)
);



/*
skid_buffer #(
    .DIN_WIDTH(DATA_WIDTH)
) skid_buffer_read1 (
    .clk(clk),
    .rst(rst),
    .din(sk_data),
    .din_valid(sk_valid), 
    .din_ready(sk_ready), 
    .dout_valid(read_tvalid), 
    .dout_ready(read_tready), 
    .dout(read_tdata)
);

*/

endmodule
