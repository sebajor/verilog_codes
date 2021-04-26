`default_nettype none

module first_one_finder #(
    parameter DIN_WIDTH = 32,
    parameter DOUT_WIDTH = $clog2(DIN_WIDTH)
) (
    input wire clk,
    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,
    output wire [DOUT_WIDTH-1:0] dout
);
integer i;
reg [DOUT_WIDTH-1:0] dout_r=0;
//only the last assignation is keeped (how is translated into hw? check!!)
always@(posedge clk)begin
    if(din==0)
        dout_r =0;
    else begin
        for(i=0; i<DIN_WIDTH; i=i+1)begin
            //dout_r =0;
            if(din[i])
                dout_r = i;
        end
    end
end
assign dout = dout_r;


endmodule
