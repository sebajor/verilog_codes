`default_nettype none

module relu #(
    parameter IN_WIDTH = 32,
    parameter IN_INT = 8,
    parameter OUT_WIDTH = 16,
    parameter OUT_INT = 4
) (
    input clk,
    input signed [IN_WIDTH-1:0] din,
    input din_valid,
    output signed [OUT_WIDTH-1:0] dout,
    output dout_valid
);
    localparam IN_POINT = IN_WIDTH-IN_INT;
    reg signed [OUT_WIDTH-1:0] dout_r =0;
    reg valid_r=0;
    generate 
        if(IN_INT> OUT_INT)begin
            always@(posedge clk)begin
                if(din_valid)begin
                    valid_r <= 1;
                    if(din[IN_WIDTH-1])
                        dout_r <= 0;
                    else begin
                        if(|din[IN_WIDTH-1:IN_POINT+OUT_INT-1])begin
                            //overflow, saturate output
                            dout_r <= {1'b0, {(OUT_WIDTH-1){1'b1}}};
                        end
                        else begin
                            //dout_r <= din[IN_POINT+OUT_INT-:OUT_WIDTH];
                            dout_r <= din[IN_POINT+OUT_INT-1-:OUT_WIDTH];
                        end
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
                    if(din[IN_WIDTH-1])
                        dout_r <= 0;
                    else begin
                        dout_r <= {{(OUT_INT-IN_INT){1'b0}}, din[IN_POINT+:IN_INT],
                                din[IN_POINT-:OUT_WIDTH-OUT_INT]};
                    end
                end
                else begin
                    dout_r <= dout_r;
                    valid_r <= 0;    
                end 
            end
        end

    endgenerate 

    assign dout = dout_r;
    assign dout_valid = valid_r;

endmodule
