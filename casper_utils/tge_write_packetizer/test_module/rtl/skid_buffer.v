`default_nettype none

module skid_buffer #(
    parameter DIN_WIDTH = 32
) (
    input wire clk,
    input wire rst,

    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid, 
    output wire  din_ready, 

    output wire dout_valid, 
    input wire dout_ready, 
    output wire [DIN_WIDTH-1:0] dout
);

reg [DIN_WIDTH-1:0] din_r=0;

//register valid
reg val=0;
always@(posedge clk)begin
    if(rst)
        val <=0;
    else if((din_valid & din_ready) && (dout_valid & ~dout_ready)) begin
        //there is din valid but dout is stalled
        val <=1;
    end 
    else if(dout_ready)
        val <= 0;
end


//register data
always@(posedge clk)begin
    if(rst)
        din_r <=0;
    else if(din_valid & din_ready)
        din_r <= din;
end

//din ready
assign din_ready = ~val;

//dout side
reg [DIN_WIDTH-1:0] dout_r=0;
reg dout_valid_r=0;


//valid
reg flag =0;
wire flag2 = din_valid | val;
always@(posedge clk)begin
    if(rst)
        dout_valid_r <=0;
    else if((~dout_valid) | dout_ready)begin
        dout_valid_r <= (din_valid | val);
        flag <= 1;
    end
    else
        flag <= 0;
end

//data
always@(posedge clk)begin
    if(rst)
        dout_r <= 0;
    else if((~dout_valid) | dout_ready)begin
        if(val)
            dout_r <= din_r;
        else if(din_valid)
            dout_r <= din;
        else
            dout_r <= 0;
    end
end

assign dout = dout_r;
assign dout_valid = dout_valid_r; 

endmodule
