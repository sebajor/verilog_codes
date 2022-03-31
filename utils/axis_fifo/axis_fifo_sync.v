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


localparam  NORMAL = 2'd0,
            ONE = 2'd1,
            TWO = 2'd3;
reg [1:0] state=NORMAL, next_state = NORMAL, prev_state=NORMAL;


always@(posedge clk)begin
    prev_state <= state;
    if(rst)
        state <= NORMAL;
    else
        state <= next_state;
end

wire read_ready;
reg [1:0] read_valid=0;

wire valid_read = read_ready & read_valid[0];
wire read_stall = ~(valid_read);

//change of state
always@(*)begin
    case(state)
        NORMAL:begin
            if(read_stall)  next_state = ONE;
            else            next_state = NORMAL;
        end
        ONE:begin
            if(read_valid[1] & ~read_ready) next_state = TWO;
            else if(valid_read)             next_state = ONE;
        end
        TWO:begin
            if(valid_read)                  next_state = ONE;
            else                            next_state = TWO;
        end
        default:
            next_state = NORMAL;
    endcase
end


always@(posedge clk)begin
    if(rst)
        raddr <=0;
    else if(read_ready & ~fifo_empty & (state==NORMAL))
        raddr <= raddr+1;
end

always@(posedge clk)begin
    if(rst)
        read_valid <=0;
    else if(state == NORMAL)
        read_valid <= {read_valid[0], (read_ready & ~fifo_empty)};
end

reg [DATA_WIDTH-1:0] rdata_r=0;
reg [DATA_WIDTH-1:0] rdata_rr=0;
always@(posedge clk)begin
    if((state==NORMAL) & read_stall)
        rdata_r <= rdata;
    else if((state==ONE) & (prev_state==TWO))
        rdata_r <= rdata_rr;
end

always@(posedge clk)begin
    if((state==ONE) & read_valid[1])
        rdata_rr <= rdata;
end

   
reg [DATA_WIDTH-1:0] dout=0;
always@(*)begin
    if(state==NORMAL)
        dout = rdata;
    else if((state==ONE) & (prev_state==TWO))
        dout = rdata_rr;
    else
        dout = rdata_rr;
end


skid_buffer #(
    .DIN_WIDTH(DATA_WIDTH)
) skid_buffer_read0 (
    .clk(clk),
    .rst(rst),
    .din(dout),
    .din_valid(read_valid[1] | (state!=NORMAL)), 
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
