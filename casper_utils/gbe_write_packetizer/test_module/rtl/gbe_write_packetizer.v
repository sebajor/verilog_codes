//`default_nettype none

module gbe_write_packetizer #(
    parameter DIN_WIDTH = 128,
    parameter FIFO_DEPTH = 512
) (
    input wire clk,
    input wire rst,
    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,
    
    //configuration signals
    input wire [31:0] pkt_len,
    input wire [31:0] sleep_cycles,
    input wire [31:0] config_tx_dest_ip,
    input wire [31:0] config_tx_dest_port,

    //to the TGE 
    output wire [7:0] tx_data,
    output wire tx_valid,
    output wire [31:0] tx_dest_ip,
    output wire [15:0] tx_dest_port,
    output wire tx_eof,

    output wire fifo_full

);

assign tx_dest_ip = config_tx_dest_ip;
assign tx_dest_port = config_tx_dest_port;


wire [7:0] tge_data;
wire tge_data_valid;


reg state=1, next_state=1;
localparam WAIT = 0;
localparam READ = 1;
always@(*)begin
    case(state)
        WAIT: begin
            if(counter==sleep_cycles)   next_state = READ;
            else                        next_state = WAIT;
        end
        READ: begin
            if((counter==pkt_len))    next_state = WAIT;
            else                        next_state = READ;
        end
    endcase
end


reg [31:0] counter=0;
wire valid_req = tge_data_valid & piso_ready;
reg eof =0;
reg [7:0] dout;
reg dout_valid =0;

always@(posedge clk)begin
    if(rst)begin
        counter <=0;
        state <= 0;
        eof <=0;
        dout_valid <=0;
    end
    else begin
        //state <= next_state;
        case(state)
            WAIT:begin
                eof <= 0;
                dout_valid <=0;
                if(counter==sleep_cycles)begin
                    counter <=0;
                    state <= READ;
                end
                else begin
                    counter<=counter+1;
                end
            end
            READ:begin
                dout <= tge_data;
                if(valid_req)begin
                    dout_valid <= 1;
                    if(counter==pkt_len)begin
                        eof <= 1;
                        counter <=0;
                        state <= WAIT;
                    end
                    else begin
                        counter <= counter+1;
                        eof <= 0;
                    end
                end
                else
                    dout_valid <=0;
            end
        endcase
    end
end

wire piso_ready;
assign piso_ready = (state==READ);

piso #(
    .DIN_WIDTH(DIN_WIDTH),
    .DOUT_WIDTH(8),
    .FIFO_DEPTH(FIFO_DEPTH)
) piso_inst (
    .clk(clk),
    .rst(rst),
    .din(din),
    .din_valid(din_valid),
    .dout(tge_data),
    .dout_valid(tge_data_valid),
    .dout_ready(piso_ready),
    .fifo_full(fifo_full)
);

assign tx_data = dout;
assign tx_valid = dout_valid;
assign tx_eof = eof;


endmodule
