`default_nettype none

module cast_signed #(
    parameter DIN_WIDTH = 16,
    parameter DIN_INT = 8,
    parameter DOUT_WIDTH = 8,
    parameter DOUT_INT = 4
) (
    input clk,
    input [DIN_WIDTH-1:0] din,
    output [DOUT_WIDTH-1:0] dout
);
/* cases:   1) din_width> dout_width & din_int > dout_int
            2) din_width> dout_width & din_int < dout_int
            3) din_width< dout_width & din_int > dout_int
            4) din_width< dout_width & din_int < dout_int
*/
localparam INT_POINT = DIN_WIDTH-DIN_INT;
localparam OUT_POINT = DOUT_WIDTH-DOUT_INT;
reg [DOUT_INT-1:0] dout_int=0;
reg [DOUT_POINT-1:0] dout_frac=0;
generate 
    if((DIN_WIDTH >= DOUT_WIDTH) & (DIN_INT >= DOUT_INT))begin
        always@(posedge clk)begin
            if(din[DIN_WIDTH-1])begin
                //negative number... mmm esto esta peluo

            end
            else begin
                //positive number 
                if(din[INT_POINT+:DIN_INT-1]>(1<<(DOUT_INT-1)) begin
                    //saturate
                    dout_int <= {1'b0, {(DOUT_INT-1)1'b1}};
                end
                else
                    dout_int <= {1'b0, din[INT_POINT+:DOUT_WIDTH]};
            end
        end

    end



endgenerate







endmodule 
