`default_nettype none
`include "covariance_matrix.v"
`include "includes.v"

module covariance_matrix_tb #(
    parameter DIN_WIDTH = 8,
    parameter DIN_POINT = 7,
    parameter N_INPUTS = 4,
    parameter DOUT_WIDTH = 32,
    parameter DOUT_POINT = 14,
    parameter INPUT_FANOUT = 2,
    parameter N_OUTPUTS = N_INPUTS*(N_INPUTS+1)/2   //just take the independant variables
) (
    input wire clk,
    input wire new_acc,

    input wire [N_INPUTS*DIN_WIDTH-1:0] din,
    input wire din_valid,

    output wire [N_OUTPUTS*DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);

covariance_matrix #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .N_INPUTS(N_INPUTS),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT),
    .INPUT_FANOUT(INPUT_FANOUT)
) cov_inst (
    .clk(clk),
    .new_acc(new_acc),
    .din(din),
    .din_valid(din_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);


wire [DOUT_WIDTH-1:0] aux0,aux1,aux2,aux3,aux4,aux5,aux6,aux7,aux8,aux9;

assign aux0 = dout[0+:DOUT_WIDTH];
assign aux1 = dout[DOUT_WIDTH+:DOUT_WIDTH];
assign aux2 = dout[2*DOUT_WIDTH+:DOUT_WIDTH];
assign aux3 = dout[3*DOUT_WIDTH+:DOUT_WIDTH];
assign aux4 = dout[4*DOUT_WIDTH+:DOUT_WIDTH];
assign aux5 = dout[5*DOUT_WIDTH+:DOUT_WIDTH];
assign aux6 = dout[6*DOUT_WIDTH+:DOUT_WIDTH];
assign aux7 = dout[7*DOUT_WIDTH+:DOUT_WIDTH];
assign aux8 = dout[8*DOUT_WIDTH+:DOUT_WIDTH];
assign aux9 = dout[9*DOUT_WIDTH+:DOUT_WIDTH];



endmodule
