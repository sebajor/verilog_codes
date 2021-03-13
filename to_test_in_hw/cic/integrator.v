`default_nettype none

module integrator #(
    parameter DIN_WIDTH = 16,
    parameter DOUT_WIDTH = 32,
    parameter STAGES = 3
) (
    input wire clk_in,
    input wire rst,
    input wire signed [DIN_WIDTH-1:0] din,
    output wire signed [DOUT_WIDTH-1:0] dout
);

genvar m;
generate 
for(m=0; m<STAGES;m=m+1)begin :int_loop
    reg signed [DOUT_WIDTH-1:0] dout_r=0;
    if(m==0)begin
        always@(posedge clk_in)begin
            if(rst)
                dout_r <= 0;
            else
                dout_r <= $signed(dout_r)+$signed(din);
        end
    end
    else begin
        always@(posedge clk_in)begin
            if(rst)
                dout_r <= 0;
            else
                dout_r <= $signed(dout_r)+$signed(int_loop[m-1].dout_r);
        end
    end
end

assign dout = $signed(int_loop[STAGES-1].dout_r);
endgenerate


endmodule
