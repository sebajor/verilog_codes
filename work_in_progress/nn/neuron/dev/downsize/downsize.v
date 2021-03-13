`default_nettype none

//this has 2 cycles of delays, nop just one cycle
//review timming!!!!!
module downsize #(
    parameter PARALLEL_IN = 4,
    parameter DIN_WIDTH = 32,
    parameter DOUT_WIDTH = 20
) (
    input clk,
    input [PARALLEL_IN*DIN_WIDTH-1:0] din,
    output [PARALLEL_IN*DOUT_WIDTH-1:0] dout
);
    localparam SHIFT = DIN_WIDTH-DOUT_WIDTH;
    
    reg [PARALLEL_IN*DOUT_WIDTH-1:0] r_dout=0;
    /*
    genvar i;
    generate
        for(i=0; i<PARALLEL_IN; i=i+1)begin
            always@(posedge clk)begin
            r_dout[i*DOUT_WIDTH+:DOUT_WIDTH] <= $signed(din[i*DIN_WIDTH+:DIN_WIDTH])>>>(SHIFT);
            end
        end
    endgenerate
   */
    integer i;
    always @(posedge clk)begin
        for(i=0; i<PARALLEL_IN; i=i+1)begin
            //always@(posedge clk)begin
            r_dout[i*DOUT_WIDTH+:DOUT_WIDTH] <= $signed(din[i*DIN_WIDTH+:DIN_WIDTH])>>>(SHIFT);
            //end
        end
    end
    assign dout = r_dout;
endmodule 
