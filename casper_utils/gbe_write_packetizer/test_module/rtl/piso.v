//`default_nettype none

/* DIN --> FIFO --> time multiplex -->DOUT */

module piso #(
    parameter DIN_WIDTH = 512,
    parameter DOUT_WIDTH = 64,
    parameter FIFO_DEPTH = 64,
    //stupid ise dont allow $clog2 in localparam
    parameter CYCLES = DIN_WIDTH/DOUT_WIDTH,
    parameter TIME_SIZE = $clog2(CYCLES)
) (
    input wire clk,
    input wire rst,

    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,

    output wire [DOUT_WIDTH-1:0] dout,
    output wire dout_valid,
    input wire dout_ready,

    output wire fifo_full
);

//localparam CYCLES = DIN_WIDTH/DOUT_WIDTH;

/***
 ***   FIFO
 ***/
reg [$clog2(FIFO_DEPTH):0] waddr=0, raddr=0;
wire ren;
wire [DIN_WIDTH-1:0] dout_fifo;

//write pointer
always@(posedge clk)begin
    if(rst)
        waddr <=0;
    else if(din_valid & ~full)
        waddr <= waddr+1;
end

bram_infer #(
    .N_ADDR(FIFO_DEPTH),
    .DATA_WIDTH(DIN_WIDTH)
) bram_inst (
    .clk(clk),
    .wen(din_valid),
    .ren(ren),
    .wadd(waddr[$clog2(FIFO_DEPTH)-1:0]),
    .radd(raddr[$clog2(FIFO_DEPTH)-1:0]),
    .win(din),
    .wout(dout_fifo)
);
//fifo control signals

wire empty, full;
assign empty = (waddr==raddr);
assign full = ((waddr[$clog2(FIFO_DEPTH)] != (raddr[$clog2(FIFO_DEPTH)])) &
            (waddr[$clog2(FIFO_DEPTH)-1:0]== raddr[$clog2(FIFO_DEPTH)-1:0]));

//read pointer
always@(posedge clk)begin
    if(rst)
        raddr <=0;
    else if(ren)
        raddr <= raddr+1;
end

assign ren = (~empty & (state==IDLE) & sk_ready);

/***
 ***    Time multiplex
 ***/

reg [$clog2(CYCLES):0] time_multiplex=0;
localparam IDLE = 1'b0;
localparam BUSY = 1'b1;
reg state=0, next_state=0;

always@(posedge clk)begin
    if(rst)
        state <= IDLE;
    else
        state <= next_state;
end

always@(*)begin
    case(state)
        IDLE: begin
            if(~empty & sk_ready)  next_state = BUSY;
            else        next_state = IDLE;
        end
        BUSY: begin
            if((time_multiplex==(CYCLES-1)) & ~stall)   next_state = IDLE; 
            else                                        next_state = BUSY;
        end
    endcase
end

//control signals
wire stall = sk_valid & ~sk_ready;
reg dout_valid_r=0;
always@(posedge clk)begin
    case(state)
        IDLE: begin
            //time_multiplex <={($clog2(CYCLES)+1){1'b1}};
            time_multiplex <={(TIME_SIZE+1){1'b1}};
            dout_valid_r <=0;
        end
        BUSY:begin
            if(stall)
                dout_valid_r <=1;
            else begin 
                time_multiplex <= time_multiplex+1;
                dout_valid_r <=1;
            end
        end
    endcase
end

reg [DOUT_WIDTH-1:0] serial_out = 0;
always@(*)
    serial_out = dout_fifo[DOUT_WIDTH*time_multiplex+:DOUT_WIDTH];

/*
reg dout_valid_rr=0;
always@(posedge clk)begin
    serial_out <= dout_fifo[DOUT_WIDTH*time_multiplex+:DOUT_WIDTH];
    dout_valid_rr <= dout_valid_r;
end
*/
wire sk_ready, sk_valid;
assign sk_valid = dout_valid_r & (state==BUSY);

skid_buffer #(
    .DIN_WIDTH(DOUT_WIDTH)
)skid_buffer_inst (
    .clk(clk),
    .rst(rst),
    .din(serial_out),
    .din_valid(sk_valid), 
    .din_ready(sk_ready), 
    .dout_valid(dout_valid), 
    .dout_ready(dout_ready), 
    .dout(dout)
);

assign fifo_full = full;
endmodule
