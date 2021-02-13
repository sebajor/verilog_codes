`default_nettype none

module relu #(
    parameter DIN_WIDTH = 32,
    parameter DIN_INT = 8,
    parameter DOUT_WIDTH = 16,
    parameter DOUT_INT =4
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din,
    input wire din_valid,
    output wire signed [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);
localparam DIN_POINT = DIN_WIDTH-DIN_INT;
localparam DOUT_POINT = DOUT_WIDTH-DOUT_INT;
reg signed [DOUT_WIDTH-1:0] dout_r=0;
reg valid_r=0;

assign dout_valid = valid_r;
assign dout = dout_r;    


generate
    if(DIN_INT>DOUT_INT)begin
        //to check if the input value saturate in some way
        //it only could be when is positive
        always@(posedge clk)begin
            if(din_valid)begin
                valid_r <=1;
                if(din[DIN_WIDTH-1])begin
                    //input is negative so set dout to zero
                    dout_r <= 0;
                end
                else begin
                    //input is positive
                    if(|din[DIN_WIDTH-1:DIN_POINT+DOUT_INT-1])begin
                        //din value is bigger than the dout representation
                        //so saturate the output
                        dout_r <= {1'b0, {(DOUT_WIDTH-1){1'b1}}};
                    end
                    else begin
                        //din value fit into output representation
                        dout_r <= din[DIN_POINT+DOUT_INT-1-:DOUT_WIDTH];
                    end
                end
            end
            else begin
                dout_r <= dout_r;
                valid_r <= 0;
            end
        end
    end
    else if((DIN_INT)==(DOUT_INT))begin
        always@(posedge clk)begin
            if(din_valid)begin
                valid_r <= 1;
                if(din[DIN_WIDTH-1])
                    dout_r <= 0;
                else begin
                    dout_r <= din[DIN_WIDTH-1-:(DOUT_WIDTH)];
                end
            end
            else begin
                dout_r <= dout_r;
                valid_r <= 0;
            end
        end
    end
    else begin
        always@(posedge clk)begin
            if(din_valid)begin
                valid_r <= 1;
                if(din[DIN_WIDTH-1])
                    dout_r <= 0;
                else begin
                    //check what happend when dout_int=din_int, error?
                    dout_r <= {{(DOUT_INT-DIN_INT){1'b0}}, din[DIN_POINT+:DIN_INT],
                                din[DIN_POINT-1-:DOUT_POINT]};
                    //dout_r <= {{(DOUT_INT-DIN_INT){1'b0}}, din[DIN_POINT+DIN_INT-:DIN_WIDTH]};
                end
            end
            else begin
                dout_r <= dout_r;
                valid_r <= 0;
            end
        end
    end
endgenerate








endmodule
