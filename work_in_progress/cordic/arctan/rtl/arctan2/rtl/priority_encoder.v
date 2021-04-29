`default_nettype none


module priority_encoder #(
    parameter DIN_WIDTH = 32,
    parameter DOUT_WIDTH = $clog2(DIN_WIDTH)
) (
    input wire [DIN_WIDTH-1:0] din,
    output wor [DOUT_WIDTH-1:0] dout
);
genvar i,j;
generate 
    for(i=0; i<DIN_WIDTH; i=i+1) begin : i_loop
        for(j=0; j<DOUT_WIDTH; j=j+1) begin: j_loop
            if(i[j])
                assign dout[j] = din[i];
        end
    end
endgenerate

endmodule
