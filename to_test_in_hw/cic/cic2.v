`default_nettype none
`include "integrator.v"
`include "comb.v"


module cic2 #(
    parameter DIN_WIDTH = 16,
    parameter STAGES = 3,     //M  
    parameter DECIMATION = 8, //R
    parameter DIFF_DELAY = 1,  //N=D/R
    //parameter DOUT_WIDTH = DIN_WIDTH + STAGES*$clog2(DECIMATION*DIFF_DELAY)
    parameter DOUT_WIDTH =32 //review the actual value!
) (
    input wire clk_in,
    input wire rst,

    input wire signed [DIN_WIDTH-1:0] din,
    output wire signed [DOUT_WIDTH-1:0] dout,
    output wire clk_out
);


wire signed [DOUT_WIDTH-1:0] int_out;
integrator #(
    .DIN_WIDTH(DIN_WIDTH),
    .DOUT_WIDTH(DOUT_WIDTH),
    .STAGES(STAGES)
) integrator_inst (
    .clk_in(clk_in),
    .rst(rst),
    .din(din),
    .dout(int_out)
);

//rst signal, this wont work if stages=1 :(
reg [STAGES-1:0] rst_delay=0;
always@(posedge clk_in)begin
    rst_delay <= {rst_delay[STAGES-2:0], rst};
end


//decimation
reg new_clk=0;
reg [$clog2(DECIMATION/2)-1:0] counter=0;
reg signed [DOUT_WIDTH-1:0] dec_out=0;
reg dec_rst =0;


always@(posedge clk_in)begin
    if(counter==DECIMATION/2-1)begin
        counter <= 0;
        new_clk <= ~new_clk;
        if(new_clk)begin
            dec_out <= $signed(int_out);
            dec_rst <= rst_delay[STAGES-1];
        end
        else begin
            dec_out <= dec_out;
            dec_rst <= dec_rst;
        end
    end
    else begin
        counter <= counter +1;
    end
end
assign clk_out = new_clk;

//comb part
comb #(
    .DATA_WIDTH(DOUT_WIDTH),
    .DIFF_DELAY(DIFF_DELAY),
    .STAGES(STAGES)
) comb_inst (
    .clk(clk_out),
    .rst(dec_rst),
    .din(dec_out),
    .dout(dout)
);



endmodule
