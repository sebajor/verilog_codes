`default_nettype none
`include "bram_infer.v"

/* DIN --> FIFO -->time multiplex -->DOUT
*/

module piso #(
    parameter DIN_WIDTH = 512,
    parameter DOUT_WIDTH = 64,
    parameter FIFO_DEPTH = 64

) (
    input wire clk,
    input wire rst,

    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,
    
    output wire [DOUT_WIDTH-1:0] dout,
    output wire dout_valid,
    input wire dout_ready
);

localparam CYCLES = DIN_WIDTH/DOUT_WIDTH;

reg [$clog2(FIFO_DEPTH):0] waddr=0, raddr=0;
wire ren;
wire [DIN_WIDTH-1:0] dout_fifo;

//write logic
always@(posedge clk) begin
    if(rst)
        waddr <=0;
    else if(din_valid && ~full)
        waddr <= waddr+1;
    else 
        waddr <= waddr;    
end

bram_infer #(
    .N_ADDR(FIFO_DEPTH),
    .DATA_WIDTH(DIN_WIDTH)
) bram_infer_inst (
    .clk(clk),
    .wen(din_valid),
    .ren(ren),
    .wadd(waddr[$clog2(FIFO_DEPTH)-1:0]),
    .radd(raddr[$clog2(FIFO_DEPTH)-1:0]),
    .win(din),
    .wout(dout_fifo)
);

wire empty, full;
assign empty = (waddr==raddr);
assign full = ((waddr[$clog2(FIFO_DEPTH)]) != (raddr[$clog2(FIFO_DEPTH)])) 
                && (waddr[$clog2(FIFO_DEPTH)-1:0]==raddr[$clog2(FIFO_DEPTH)-1:0]);

assign ren = (~empty)&&(dout_ready)&&(time_multiplex==(CYCLES-1));

//read data
always@(posedge clk)begin
    if(rst)
        raddr<=1;
    else if(ren)
        raddr <= raddr+1;
    else
        raddr <= raddr;
end

//time multiplex
reg [$clog2(CYCLES)-1:0] time_multiplex=0;

localparam IDLE = 1'b0;
localparam BUSY = 1'b1;
reg state =0, next_state=0;

always@(posedge clk)begin
    if(rst)
        state <= IDLE;
    else 
        state <= next_state;
end

always@(*)begin
    case(state)
        IDLE: begin
            if(~empty)  next_state = BUSY;
            else        next_state = IDLE;
        end
        BUSY: begin
            if(time_multiplex == (CYCLES-1) && empty)    next_state = IDLE;
            else                                next_state = BUSY;
        end
       // default:    next_state = IDLE;
    endcase
end

//control signals
reg dout_valid_r=0;

always@(posedge clk)begin
    case(state)
        IDLE:begin
            time_multiplex <= 0;//{$clog2(CYCLES){1'b1}};
            dout_valid_r<= 0;
        end
        BUSY:begin
            if(dout_ready)begin
                time_multiplex <= time_multiplex+1;
                dout_valid_r <=1;
            end
        end
    endcase
end

reg [DOUT_WIDTH-1:0] serial_out=0;
reg dout_valid_rr=0;
always@(posedge clk)begin
    serial_out <= dout_fifo[DOUT_WIDTH*time_multiplex+:DOUT_WIDTH];
    dout_valid_rr <= dout_valid_r;
end

//enable the dout after the first reading
reg first_read=0, first_read_dly=0;
always@(posedge clk)begin
    first_read_dly <= first_read;
    if(state==IDLE)
        first_read <= 0;
    else begin
        if(ren)
            first_read <=1;
    end
end

assign dout = serial_out;
assign dout_valid = dout_valid_r & dout_ready & first_read_dly;

endmodule



