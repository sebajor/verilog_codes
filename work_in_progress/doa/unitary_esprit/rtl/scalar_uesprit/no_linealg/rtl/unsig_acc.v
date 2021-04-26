`default_nettype none

/*
    accumulator, doesnt handle overflow! check your bitwidth
*/

module unsig_acc #(
    parameter DIN_WIDTH = 16,
    parameter ACC_WIDTH = 32
) (
    input wire clk,
    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,
    input wire acc_done,

    output wire [ACC_WIDTH-1:0] dout,
    output wire dout_valid
);
//register inputs for timing
reg [DIN_WIDTH-1:0] din_r=0;
reg din_valid_r=0, acc_done_r=0;
always@(posedge clk)begin
    din_r <=din;
    din_valid_r<=din_valid;
    acc_done_r <= acc_done;
end

//accumulate
reg [ACC_WIDTH-1:0] acc=0;
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

assign dout_valid = acc_done_r;
assign dout = acc;


endmodule
