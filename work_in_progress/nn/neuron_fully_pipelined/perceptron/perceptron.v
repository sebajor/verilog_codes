`default_nettype none
`include "includes.v"

module perceptron #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 15,
    parameter WEIGTH_WIDTH = 16,
    parameter WEIGTH_POINT = 15,
    parameter WEIGTH_NUMB = 64,
    parameter BIAS_WIDTH = 16,
    parameter BIAS_POINT = 15,

    //accumulation parameters
    parameter ACC_WIDTH = 48,
    parameter ACC_POINT = 30,

    //weight file
    parameter WEIGTH_FILE = "w11.hex"
) (
    input wire clk,
    input wire rst,

    input wire signed [DIN_WIDTH-1:0] din,
    input wire din_valid,

    output wire signed [ACC_WIDTH-1:0] acc_out,
    output wire acc_valid
);

reg [$clog2(WEIGTH_NUMB):0] weigth_addr=0;

always@(posedge clk)begin
    if(rst)
        weigth_addr <= 0;
    else begin
        if(din_valid)
            weigth_addr<= weigth_addr+1;
    end
end

wire signed [WEIGTH_WIDTH-1:0] weight;

rom #(
    .N_ADDR(WEIGTH_NUMB),
    .DATA_WIDTH(WEIGTH_WIDTH),
    .INIT_VALS(WEIGTH_FILE)
) rom_weigth (
    .clk(clk),
    .ren(1'b1), //din_valid),
    .radd(weigth_addr[$clog2(WEIGTH_NUMB)-1:0]),
    .wout(weight)
);

reg [DIN_WIDTH-1:0] din_r=0;
reg din_valid_r=0;
reg new_acc =0, w_addr_r=0;
always@(posedge clk)begin
    din_r <= din;
    din_valid_r <= din_valid;
    w_addr_r <= weigth_addr[$clog2(WEIGTH_NUMB)];
    new_acc <= w_addr_r ^ weigth_addr[$clog2(WEIGTH_NUMB)] | rst; //any change on the top bit 
    //new_acc <= ((weigth_addr==(WEIGTH_NUMB-1)) & din_valid) | rst ;
end

//wire new_acc = ((weigth_addr==(WEIGTH_NUMB-1)) & din_valid) | rst ;

dsp48_macc #(
    .DIN1_WIDTH(DIN_WIDTH),
    .DIN2_WIDTH(WEIGTH_WIDTH),
    .DOUT_WIDTH(ACC_WIDTH)
) macc_inst (
    .clk(clk),
    .new_acc(new_acc),
    .din1(din_r),
    .din2(weight),
    .din_valid(din_valid_r & ~rst),
    .dout(acc_out),
    .dout_valid(acc_valid)
);

endmodule
