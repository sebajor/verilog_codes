`default_nettype none

module cic #(
    parameter DIN_WIDTH = 16,
    parameter STAGES = 3,     //M  
    parameter DECIMATION = 8, //R
    parameter DIFF_DELAY = 1,  //N=D/R
    parameter DOUT_WIDTH = DIN_WIDTH + STAGES*$clog2(DECIMATION*DIFF_DELAY)
) (
    input wire clk_in,
    input wire signed [DIN_WIDTH-1:0] din,
    output wire signed [DOUT_WIDTH-1:0] dout,
    output wire clk_out, 
    input wire en
);

/* the delay of the comb part is N=D/R
*/
genvar m;
generate 
for(m=0; m<STAGES; m=m+1)begin :integrator
    reg signed [DOUT_WIDTH-1:0] integ_r=0;
    wire signed [DOUT_WIDTH-1:0] integ;
    reg en_int =0;
    if(m==0)begin
        assign integ = $signed(din)+$signed(integ_r);
        always@(posedge clk_in)begin
            integ_r <= integ;
            en_int <= en;
            //integ <= $signed(din)+$signed(integ);
        end
    end
    else begin
        assign integ = $signed(integrator[m-1].integ)+$signed(integ_r);
        always@(posedge clk_in)begin
            integ_r <= integ;
            en_int <= integrator[m-1].en_int;
            //integ <= $signed(integ) + $signed(integrator[m-1].integ);
        end
    end
end
endgenerate 

//decimation, for symplicity just take power of two decimation factor..
//so its just a clock divider, nothing fancy haha
reg new_clk=0, new_clk_d=0;
reg [$clog2(DECIMATION)-1:0] counter=0;
reg signed [DOUT_WIDTH-1:0] integ_out=0;
reg en_sub=0;
always@(posedge clk_in)begin
    if(counter==DECIMATION/2-1)begin
        new_clk <= ~ new_clk;
        counter <= 0;
        if(!new_clk) begin
            integ_out <= integrator[STAGES-1].integ;
            en_sub<=integrator[STAGES-1].en_int;
        end
        else 
            integ_out <= integ_out;
    end
    else begin 
        counter <= counter+1;
        new_clk <= new_clk;
        integ_out <= integ_out;
    end
end
assign clk_out = new_clk;
//downsampled data
//always@(posedge clk_out)begin
//    integ_out <= integrator[STAGES-1].integ;
//end

//comb part
//I guest that I need to add the delays in the subtraction to pipelined everything

genvar l;
generate 
if(DIFF_DELAY==1)begin
for(l=0; l<STAGES; l=l+1)begin: comb
    reg signed [DOUT_WIDTH-1:0] comb_reg=0;
    reg [DOUT_WIDTH-1:0] diff_dly=0; //check the diff_delay+1
    reg en_dly =0;
    if(l==0)begin
        always@(posedge clk_out)begin
            if(en_sub)begin
                diff_dly <= integ_out;
                comb_reg <= $signed(integ_out)-$signed(diff_dly);
                en_dly <=1;
            end
            //comb_reg <= $signed(integ_out)-$signed(diff_dly[DOUT_WIDTH*(DIFF_DELAY+1)-1-:DOUT_WIDTH]);
        end
    end
    else begin
        always@(posedge clk_out)begin
            if(comb[l-1].en_dly)begin
                diff_dly <= comb[l-1].comb_reg;    //here is failing !!!
                comb_reg <= $signed(comb[l-1].comb_reg)-$signed(diff_dly);
                en_dly <=1;
            end
            //I think like comb_reg depends on diff_dly it first take diff_dly as known and then calculate the comb_reg
            //this is a race condition!!! I should pipelined everything to make sense
            
            //comb_reg <= $signed(comb[l-1].comb_reg)-$signed(diff_dly[DOUT_WIDTH*(DIFF_DELAY+1)-1-:DOUT_WIDTH]);
        end
    end
end
assign dout = comb[STAGES-1].comb_reg; 
end
else begin
for(l=0; l<STAGES; l=l+1)begin: comb
    //reg signed [DOUT_WIDTH-1:0] comb_reg=0;
    reg [DOUT_WIDTH*(DIFF_DELAY+1)-1:0] diff_dly=0; //check the diff_delay+1
    reg en_dly =0;
    if(l==0)begin
        always@(posedge clk_out)begin
            if(en_sub)begin
                diff_dly <= {diff_dly[DOUT_WIDTH*(DIFF_DELAY)-1:0], integ_out};
                comb_reg <= $signed(integ_out)-$signed(diff_dly[DOUT_WIDTH*(DIFF_DELAY+1)-1-:DOUT_WIDTH]);
                en_dly <=1;
            end
            //comb_reg <= $signed(integ_out)-$signed(diff_dly[DOUT_WIDTH*(DIFF_DELAY+1)-1-:DOUT_WIDTH]);
        end
    end
    else begin
        always@(posedge clk_out)begin
            if(comb[l-1].en_dly)begin
                diff_dly <= {diff_dly[DOUT_WIDTH*(DIFF_DELAY)-1:0], comb[l-1].comb_reg};    //here is failing !!!
                comb_reg <= $signed(comb[l-1].comb_reg)-$signed(diff_dly[DOUT_WIDTH*(DIFF_DELAY+1)-1-:DOUT_WIDTH]);
                en_dly <=1;
            end
            //I think like comb_reg depends on diff_dly it first take diff_dly as known and then calculate the comb_reg
            //this is a race condition!!! I should pipelined everything to make sense
            
            //comb_reg <= $signed(comb[l-1].comb_reg)-$signed(diff_dly[DOUT_WIDTH*(DIFF_DELAY+1)-1-:DOUT_WIDTH]);
        end
    end
end
assign dout = comb[STAGES-1].comb_reg; 
end
endgenerate

//assign dout = comb[STAGES-1].comb_reg; 

endmodule
