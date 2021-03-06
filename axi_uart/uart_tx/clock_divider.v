module clock_divider #(
   parameter N_DIVISIION = 16 
) (
    input clk_in,
    output clk_out
);
    reg [$clog2(N_DIVISIION)-1:0] counter=0;
    reg r_clk=0;

    always@(posedge clk_in)begin
        if(counter == (N_DIVISIION-1)/2) begin  
            counter <=0;
            r_clk <= ~ r_clk;
            end
        else
            counter <= counter + 1;
    end

    assign clk_out = r_clk; 

endmodule 

