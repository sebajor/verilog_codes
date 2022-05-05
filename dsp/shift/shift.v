`default_nettype none

/*
    Author: Sebastian Jorquera

    parametrized bit shifting. 
    ASYNC = 1   just a wire assignation
    ASYNC = 0   makes a clocked shift
    
*/

module shift #(
    parameter DATA_WIDTH = 16,
    parameter DATA_TYPE = "unsigned", //"signed" or "unsigned"
    parameter SHIFT_VALUE = 1,      //positive <<, negative >>
    parameter ASYNC = 0,             // 
    parameter OVERFLOW_WARNING = 1
) (
    input wire clk,
    input wire [DATA_WIDTH-1:0] din,

    output wire [DATA_WIDTH-1:0] dout,
    output wire [1:0] warning
);
initial begin
    //$display("SHIFT OVERFLOW WARNING %d", OVERFLOW_WARNING);
end

generate
    if(DATA_TYPE=="signed")begin
        if(ASYNC)begin
            wire signed [DATA_WIDTH+SHIFT_VALUE-1:0] dout_temp;
            assign dout = $signed(dout_temp);
            if(SHIFT_VALUE==0)
                assign dout_temp = din;
            else if(SHIFT_VALUE>0)begin
                assign dout_temp = $signed(din)<<<(SHIFT_VALUE);
                if(OVERFLOW_WARNING)begin
                    assign warning[0] = $signed(din)>(2**(DATA_WIDTH-SHIFT_VALUE-1)-1);
                    assign warning[1] = $signed(din)<(-(2**(DATA_WIDTH-SHIFT_VALUE-1)));
                end
            end
            else
                assign dout_temp = $signed(din)>>>(-SHIFT_VALUE);
        end
        else begin
            reg signed [DATA_WIDTH+SHIFT_VALUE-1:0] dout_temp=0;
            reg [1:0] warning_r =0;
            assign warning = warning_r;
            assign dout = $signed(dout_temp);
            always@(posedge clk)begin
                if(SHIFT_VALUE==0)
                    dout_temp <= $signed(din);
                else if(SHIFT_VALUE>0)begin
                    dout_temp <= $signed(din)<<<(SHIFT_VALUE);
                    if(OVERFLOW_WARNING)begin
                        warning_r[0] <= $signed(din)>(2**(DATA_WIDTH-SHIFT_VALUE-1)-1);
                        warning_r[1] <= $signed(din)<(-(2**(DATA_WIDTH-SHIFT_VALUE-1)));
                    end
                end
                else
                    dout_temp <= $signed(din)>>>(-SHIFT_VALUE);
            end
        end
    end
    else begin
        if(ASYNC)begin
            wire [DATA_WIDTH+SHIFT_VALUE-1:0] dout_temp;
            assign dout = dout_temp;
            if(SHIFT_VALUE==0)
                assign dout_temp = din;
            else if(SHIFT_VALUE>0)begin
                assign dout_temp = $unsigned(din)<<(SHIFT_VALUE);
                if(OVERFLOW_WARNING)
                    assign warning = $unsigned(din) > (2**(DATA_WIDTH-SHIFT_VALUE)-1);
            end
            else
                assign dout_temp = $unsigned(din)>>(-SHIFT_VALUE);
        end
        else begin
            reg [DATA_WIDTH+SHIFT_VALUE-1:0] dout_temp=0;
            assign dout = dout_temp;
            reg [1:0] warning_r =0;
            assign warning = warning_r;
            always@(posedge clk)begin
                if(SHIFT_VALUE==0)
                    dout_temp <= $unsigned(din);
                else if(SHIFT_VALUE>0)begin
                    dout_temp <= $unsigned(din)<<(SHIFT_VALUE);
                    if(OVERFLOW_WARNING)
                        warning_r <= $unsigned(din) > (2**(DATA_WIDTH-SHIFT_VALUE)-1);
                end
                else
                    dout_temp <= $unsigned(din)>>(-SHIFT_VALUE);
            end
        end
    end
endgenerate


endmodule
