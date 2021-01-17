`default_nettype none 

module comb #(
    parameter DATA_WIDTH  = 16,
    parameter DIFF_DELAY = 1,
    parameter STAGES = 3
) (
    input wire clk,
    input wire rst,
    input wire signed [DATA_WIDTH-1:0] din,
    output wire signed [DATA_WIDTH-1:0] dout
);


//maybe add the reset logic!
genvar l;
generate 
if(DIFF_DELAY==1)begin
    for(l=0; l<STAGES; l=l+1)begin: comb_loop
        reg signed [DATA_WIDTH-1:0] comb_reg = 0;
        reg signed [DATA_WIDTH-1:0] diff_delay=0;
        if(l==0)begin
            always@(posedge clk)begin
                if(rst)begin
                    comb_reg <= 0;
                    diff_delay <= 0;
                end
                else begin
                    comb_reg <= $signed(din)-$signed(diff_delay); 
                    diff_delay <= din;
                end
            end
        end
        else begin
            always@(posedge clk)begin
                if(rst)begin
                    comb_reg <= 0;
                    diff_delay <=0;
                end
                else begin
                    //the order of the operation matters?
                    comb_reg <= $signed(comb_loop[l-1].comb_reg)-$signed(diff_delay);
                    diff_delay <= comb_loop[l-1].comb_reg;
                end
            end
        end
    end
    assign dout = $signed(comb_loop[STAGES-1].comb_reg); 
end
else begin 
    for(l=0; l<STAGES; l=l+1)begin: comb
        reg signed [DATA_WIDTH-1:0] comb_reg = 0;
        reg signed [DATA_WIDTH*(DIFF_DELAY+1)-1:0] diff_fly=0;
        if(l==0)begin
            always@(posedge clk)begin
                if(rst)begin
                    comb_reg <= 0;
                    diff_delay <=0;
                end
                else begin
                    comb_reg <= $signed(din)-$signed(diff_delay); 
                    diff_dly <= {diff_dly[DATA_WIDTH*(DIFF_DELAY+1)-1:DATA_WIDTH], din};
                end
            end
        end
        else begin
            always@(posedge clk)begin
                if(rst)begin
                    comb_reg <=0;
                    diff_delay <= 0;
                end
                else begin
                    //the order of the operation matters?
                    comb_reg <= $signed(comb_loop[l-1].comb_reg)-$signed(diff_delay);
                    diff_delay <= {diff_dly[DATA_WIDTH*(DIFF_DELAY+1)-1:DATA_WIDTH], comb_loop[l-1].comb_reg};
                end
            end
        end
    end
    assign dout = $signed(comb_loop[STAGES-1].comb_reg); 
end

endgenerate 



endmodule
