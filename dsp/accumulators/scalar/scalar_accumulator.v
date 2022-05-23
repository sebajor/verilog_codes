
`default_nettype none

/*
*   Author: Sebastian Jorquera}
*   
*   accumulator, doesnt handle overflow! check your bitwidth
*   the acc_done should be asserted after the last sample ie 
*   in the first word of the new accumulation
*
*/

module scalar_accumulator #(
    parameter DIN_WIDTH = 16,
    parameter ACC_WIDTH = 32,
    parameter DATA_TYPE = "signed"
) (
    input wire clk,
    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,
    input wire acc_done,

    output wire [ACC_WIDTH-1:0] dout,
    output wire dout_valid
);
//register inputs for timing
reg signed [DIN_WIDTH-1:0] din_r=0;
reg din_valid_r=0, acc_done_r=0;
always@(posedge clk)begin
    din_r <=din;
    din_valid_r<=din_valid;
    acc_done_r <= acc_done;
end

//accumulate
reg [ACC_WIDTH-1:0] acc=0;
generate
    if(DATA_TYPE=="signed")begin
        always@(posedge clk)begin
            if(din_valid_r)begin
                if(acc_done_r)
                    acc <= $signed(din_r);
                else
                    acc <= $signed(acc)+$signed(din_r);
            end
            else
                acc <= acc;
        end
    end
    else begin
        always@(posedge clk)begin
            if(din_valid_r)begin
                if(acc_done_r)
                    acc <= din_r;
                else
                    acc <= acc+din_r;
            end
            else
                acc <= acc;
        end
    end
endgenerate

assign dout_valid = acc_done_r & din_valid_r;//acc_done_r;
assign dout = acc;


endmodule
