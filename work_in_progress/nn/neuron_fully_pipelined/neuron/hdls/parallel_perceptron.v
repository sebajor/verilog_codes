`default_nettype none

module parallel_perceptron #(
    parameter PARALLEL = 4,
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
    parameter WEIGHT_HEAD = "w1"
) (
    input wire clk,
    input wire rst,
    input wire signed [PARALLEL*DIN_WIDTH-1:0] din,
    input wire din_valid,

    output wire signed [$clog2(PARALLEL)+ACC_WIDTH-1:0] acc_out,
    output wire acc_valid
);

parameter WEIGHT_TAIL = ".hex";

generate 
    if(PARALLEL==1)begin
        localparam text = {WEIGHT_HEAD, WEIGHT_TAIL};
        wire [ACC_WIDTH-1:0] acc_out;
        wire acc_valid;
        perceptron #(
            .DIN_WIDTH(DIN_WIDTH),
            .DIN_POINT(DIN_POINT),
            .WEIGTH_WIDTH(WEIGTH_WIDTH),
            .WEIGTH_POINT(WEIGTH_POINT),
            .WEIGTH_NUMB(WEIGTH_NUMB),
            .BIAS_WIDTH(BIAS_WIDTH),
            .BIAS_POINT(BIAS_POINT),
            .ACC_WIDTH(ACC_WIDTH),
            .ACC_POINT(ACC_POINT),
            .WEIGTH_FILE(text)
        ) perceptron_inst (
            .clk(clk),
            .rst(rst),
            .din(din),
            .din_valid(din_valid),
            .acc_out(acc_out),
            .acc_valid(acc_valid)
        );
    end
    else begin
        wire [PARALLEL*ACC_WIDTH-1:0] acc_out_pre;
        wire [PARALLEL-1:0] acc_valid_pre;
        genvar i;
        for(i=0; i<PARALLEL; i=i+1)begin: percept_inst
            localparam integer temp = 48+i;
            localparam text = {WEIGHT_HEAD, temp, WEIGHT_TAIL};
                perceptron #(
                    .DIN_WIDTH(DIN_WIDTH),
                    .DIN_POINT(DIN_POINT),
                    .WEIGTH_WIDTH(WEIGTH_WIDTH),
                    .WEIGTH_POINT(WEIGTH_POINT),
                    .WEIGTH_NUMB(WEIGTH_NUMB),
                    .BIAS_WIDTH(BIAS_WIDTH),
                    .BIAS_POINT(BIAS_POINT),
                    .ACC_WIDTH(ACC_WIDTH),
                    .ACC_POINT(ACC_POINT),
                    .WEIGTH_FILE(text)
                ) perceptron_inst (
                    .clk(clk),
                    .rst(rst),
                    .din(din[DIN_WIDTH*i+:DIN_WIDTH]),
                    .din_valid(din_valid),
                    .acc_out(acc_out_pre[ACC_WIDTH*i+:ACC_WIDTH]),
                    .acc_valid(acc_valid_pre[i])
                );
        end

        adder_tree #(
            .DATA_WIDTH(ACC_WIDTH),
            .PARALLEL(PARALLEL)
        ) adder_tree_inst (
            .clk(clk),
            .din(acc_out_pre),
            .in_valid(acc_valid_pre[0]),
            .dout(acc_out),
            .out_valid(acc_valid)
        );
    end
endgenerate





endmodule 
