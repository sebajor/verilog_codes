`default_nettype none
`include "correlation_matrix.v"

module correlation_matrix_tb #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    parameter VECTOR_LEN = 64,
    parameter ACC_WIDTH = 20,
    parameter ACC_POINT = 16,
    parameter DOUT_WIDTH = 32
) (
    input wire clk,
    input wire rst,

    input wire new_acc, //this one should come before the first valid value of 
                        //the frame
    input wire signed [DIN_WIDTH-1:0] din1_re, din1_im,
    input wire signed [DIN_WIDTH-1:0] din2_re, din2_im,
    input wire din_valid,

    output wire [DOUT_WIDTH-1:0] r11, r22, r12_re, r12_im,
    output wire dout_valid
);



correlation_matrix #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .VECTOR_LEN(VECTOR_LEN),
    .ACC_WIDTH(ACC_WIDTH),
    .ACC_POINT(ACC_POINT),
    .DOUT_WIDTH(DOUT_WIDTH)
) corr_mat_inst (
    .clk(clk),
    .rst(rst),
    .new_acc(new_acc), 
    .din1_re(din1_re),
    .din1_im(din1_im),
    .din2_re(din2_re),
    .din2_im(din2_im),
    .din_valid(din_valid),
    .r11(r11),
    .r22(r22),
    .r12_re(r12_re),
    .r12_im(r12_im),
    .dout_valid(dout_valid)
);

reg [$clog2(VECTOR_LEN)-1:0] counter_db=0, counter_db2=0;
always@(posedge clk)begin
    if(dout_valid)
        counter_db <= counter_db+1;
    if(din_valid)
        counter_db2 <= counter_db2 +1;
end



initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end


endmodule 
