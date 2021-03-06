`default_nettype none


module tremolo #(
    parameter DIN_WIDTH = 32,
    parameter FS = 44_100,      //audio sampling freq
    parameter TREMOLO_PERIOD = 2,
    parameter MEM_DEPTH = 1024 

) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din,
    input wire din_tvalid,
    input wire din_tready,
    output wire signed [DIN_WIDTH-1:0] dout,
    output wire dout_tvalid,
    output wire dout_tready
);

reg [$clog2(MEM_DEPTH)-1:0] mem [MEM_DEPTH-1:0];
    
integer i;
initial begin
    for(i=0; i<MEM_DEPTH; i=i+1)begin
        if(i==0)
            mem[i] <= 1;
        else
            mem[i] <= i;
    end
end



reg [$clog2(TREMOLO_PERIOD*FS)-1:0]  count=0;
reg up_down_count=0;

always@(posedge clk)begin
    if(din_tvalid)begin
        if(&count)begin
            up_down_count <= 1;
            count <= count-1;
        end
        else if(count==0)begin
            up_down_count <= 0;
            count <= count+1;
        end
        else if(~up_down_count)begin
            count <= count+1;
        end
        else if(up_down_count)begin
            count <= count-1;
        end
        else begin
            count <= count;
            up_down_count <= up_down_count;
        end
    end
end

reg din_valid_dly=0;
reg [$clog2(MEM_DEPTH):0] mem_read=1;
always@(posedge clk)begin
    din_valid_dly <= din_tvalid;
    mem_read <= {1'b0, mem[count[$clog2(TREMOLO_PERIOD*FS)-:MEM_DEPTH]]};
end

reg signed [DIN_WIDTH+$clog2(MEM_DEPTH):0] dout_r=0;
assign dout = dout_r[DIN_WIDTH+$clog2(MEM_DEPTH)-:DIN_WIDTH];
always@(posedge clk)begin
    dout_r <= $signed(din)*$signed(mem_read);
end







endmodule
