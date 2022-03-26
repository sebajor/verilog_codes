`default_nettype none

/*
    Author: Sebastian Jorquera

    parametrized bit shifting. 
    ASYNC = 1   just a wire assignation
    ASYNC = 0   makes a clocked shift
    
*/

module shift #(
    parameter DATA_WIDTH = 16,
    parameter DATA_TYPE = "signed", //"signed" or "unsigned"
    parameter SHIFT_VALUE = -1,      //positive <<, negative >>
    parameter ASYNC = 0             // 
) (
    input wire clk,
    input wire [DATA_WIDTH-1:0] din,

    output wire [DATA_WIDTH-1:0] dout
);

generate
    if(DATA_TYPE=="signed")begin
        if(ASYNC)begin
            wire signed [DATA_WIDTH-1:0] dout_temp;
            assign dout = dout_temp;
            if(SHIFT_VALUE==0)
                assign dout_temp = din;
            else if(SHIFT_VALUE>0)
                assign dout_temp = $signed(din)<<<(SHIFT_VALUE);
            else
                assign dout_temp = $signed(din)>>>(-SHIFT_VALUE);
        end
        else begin
            reg signed [DATA_WIDTH-1:0] dout_temp=0;
            assign dout = dout_temp;
            always@(posedge clk)begin
                if(SHIFT_VALUE==0)
                    dout_temp <= $signed(din);
                else if(SHIFT_VALUE>0)
                    dout_temp <= $signed(din)<<<(SHIFT_VALUE);
                else
                    dout_temp <= $signed(din)>>>(-SHIFT_VALUE);
            end
        end
    end
    else begin
        if(ASYNC)begin
            wire [DATA_WIDTH-1:0] dout_temp;
            assign dout = dout_temp;
            if(SHIFT_VALUE==0)
                assign dout_temp = din;
            else if(SHIFT_VALUE>0)
                assign dout_temp = $unsigned(din)<<(SHIFT_VALUE);
            else
                assign dout_temp = $unsigned(din)>>(-SHIFT_VALUE);
        end
        else begin
            reg [DATA_WIDTH-1:0] dout_temp=0;
            assign dout = dout_temp;
            always@(posedge clk)begin
                if(SHIFT_VALUE==0)
                    dout_temp <= $unsigned(din);
                else if(SHIFT_VALUE>0)
                    dout_temp <= $unsigned(din)<<(SHIFT_VALUE);
                else
                    dout_temp <= $unsigned(din)>>(-SHIFT_VALUE);
            end
        end
    end
endgenerate


endmodule
