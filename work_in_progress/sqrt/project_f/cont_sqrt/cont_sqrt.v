`default_nettype none
`include "rtl/sqrt_fix.v"

module cont_sqrt #(
    parameter DIN_WIDTH = 8,
    parameter DIN_POINT = 6
) (
    input wire clk, 
    input wire rst,
    input wire din_valid,
    input wire [DIN_WIDTH-1:0] din,
    output wire [DIN_WIDTH-1:0] dout,
    output wire dout_valid
);

localparam ITERS= (DIN_WIDTH+DIN_POINT)/2+1;
reg [$clog2(ITERS)-1:0] i_count=0;
reg [$clog2(ITERS)-1:0] o_count=0;

//register the input values
reg [DIN_WIDTH-1:0] din_r=0;
reg din_valid_r=0;
always@(posedge clk)begin
    din_r <= din;
    din_valid_r <= din_valid;
end

always@(posedge clk)begin
    if(rst)
        i_count <=0;
    else if(din_valid_r)begin
        if(i_count==(ITERS-1))
            i_count <=0;
        else
            i_count <= i_count +1;
    end
end


wire [ITERS-1:0] sqrt_dout_val;
wire [DIN_WIDTH*ITERS-1:0] sqrt_dout;

genvar i;
generate 
for(i=0; i<ITERS; i=i+1) begin
    wire index_valid = (i ==i_count) & din_valid_r;
    sqrt_fix #(
        .DIN_WIDTH(DIN_WIDTH),
        .DIN_POINT(DIN_POINT)
    )sqrt_fix_inst (
        .clk(clk),
        .busy(),
        .din_valid(index_valid),
        .din(din_r),
        .dout(sqrt_dout[DIN_WIDTH*i+:DIN_WIDTH]),
        .reminder(),
        .dout_valid(sqrt_dout_val[i])
    );
end

endgenerate


reg [DIN_WIDTH-1:0] dout_r=0;
reg dout_valid_r=0;
wire sqrt_valid = |sqrt_dout_val;

always@(posedge clk)begin
    if(rst)
        o_count <=0;
    else if(sqrt_valid)begin
        if(o_count == (ITERS-1))
            o_count <=0;
        else
            o_count <= o_count+1;
    end
end

always@(posedge clk)begin
    if(sqrt_valid)begin
        dout_r <= sqrt_dout[o_count*DIN_WIDTH+:DIN_WIDTH];
        dout_valid_r <= 1;
    end
    else
        dout_valid_r <=0;
end

assign dout_valid = dout_valid_r;
assign dout = dout_r;


endmodule
