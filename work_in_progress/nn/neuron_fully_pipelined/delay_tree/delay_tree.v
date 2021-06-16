`default_nettype none

module delay_tree #(
    parameter DIN_WIDTH = 8,
    parameter STAGES = 3    //in each stage we duplicate the width
)(
    input wire clk,
    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,

    output wire [(2**(STAGES-1))*DIN_WIDTH-1:0] dout,
    output wire dout_valid
);

reg [STAGES-1:0] valid=0;
always@(posedge clk)
    valid <= {valid[STAGES-2:0], din_valid};

assign dout_valid = valid[STAGES-1];

genvar i;
genvar j;
generate 
for(i=0; i<STAGES; i=i+1)begin: outer
    reg [DIN_WIDTH*(2**i)-1:0] din_r=0;
    if(i==0)begin
        always@(posedge clk)
            din_r <= din;
    end
    else begin
        for(j=0; j<2**(i-1);j=j+1)begin:inner
            always@(posedge clk)
                din_r[DIN_WIDTH*2*j+:2*DIN_WIDTH] <= {2{outer[i-1].din_r[DIN_WIDTH*j+:DIN_WIDTH]}};
        end
    end
end
endgenerate

assign dout = outer[STAGES-1].din_r;

endmodule
