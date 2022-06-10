`default_nettype none

/*
*   Author: Sebastian Jorquera
*   This module computes a covariance matrix in the time domain
*
*/


module covariance_matrix #(
    parameter DIN_WIDTH = 8,
    parameter DIN_POINT = 7,
    parameter N_INPUTS = 8,
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

localparam INPUT_WIDTH = N_INPUTS*DIN_WIDTH;
//put some register for the fanout
wire [INPUT_WIDTH-1:0] input_data;
wire input_valid;
wire input_new_acc;
generate 
    if(INPUT_FANOUT==0)begin
        assign input_data = din;
        assign input_valid = din_valid;
        assign input_new_acc = new_acc;
    end
    else if(INPUT_FANOUT==1)begin
        reg [INPUT_WIDTH-1:0] din_r=0;
        reg din_valid_r =0;
        reg new_acc_r =0;
        always@(posedge clk)begin
            din_r <= din;
            din_valid_r <= din_valid;
            new_acc_r <= new_acc;
        end
        assign input_data = din_r;
        assign input_valid = din_valid_r;
        assign input_new_acc = new_acc_r;
    end
    else begin
        reg [INPUT_WIDTH*INPUT_FANOUT-1:0] din_r=0;
        reg [INPUT_FANOUT-1:0] din_valid_r=0, new_acc_r=0;
        always@(posedge clk)begin
            din_r <= {din_r[(INPUT_FANOUT-1)*INPUT_WIDTH-1:0], din};
            din_valid_r <= {din_valid_r[INPUT_FANOUT-2:0], din_valid};
            new_acc_r <= {new_acc_r[INPUT_FANOUT-2:0], new_acc};
        end
        assign input_data = din_r[INPUT_FANOUT*INPUT_WIDTH-1-:INPUT_WIDTH];
        assign input_valid = din_valid_r[INPUT_FANOUT-1];
        assign input_new_acc = new_acc_r[INPUT_FANOUT-1];
    end
endgenerate

//we need to iterate between the input signals, but we just want to move
//in the upper triangle of the matrix because the matrix is symmetrical
genvar i, j;
generate 
    for(i=0; i<N_INPUTS; i=i+1)begin:loop_i
        wire [(N_INPUTS-i)*DOUT_WIDTH-1:0] concat_temp;
        for(j=i; j<N_INPUTS; j=j+1)begin:loop_j
            wire temp_dout_valid;
            wire signed [DOUT_WIDTH-1:0] temp_dout;
            dsp48_macc #(
                .DIN1_WIDTH(DIN_WIDTH),
                .DIN2_WIDTH(DIN_WIDTH),
                .DOUT_WIDTH(DOUT_WIDTH)
            ) macc_inst (
                .clk(clk),
                .new_acc(input_new_acc),
                .din1(input_data[i*DIN_WIDTH+:DIN_WIDTH]),
                .din2(input_data[j*DIN_WIDTH+:DIN_WIDTH]),
                .din_valid(input_valid),
                .dout(temp_dout),
                .dout_valid(temp_dout_valid)
            );
            assign concat_temp[(j-i)*DOUT_WIDTH+:DOUT_WIDTH] = temp_dout;
        end 
        localparam ind = index_summing(i, N_INPUTS);
        wire [10:0] asd = ind*DOUT_WIDTH;
        if(i==0)begin
            //assign dout[0+:ind*DOUT_WIDTH] = concat_temp;
            assign dout[ind*DOUT_WIDTH-1:0] = concat_temp;
        end
        else begin
            localparam prev_ind = index_summing(i-1, N_INPUTS);
            wire [10:0] qwe = prev_ind*DOUT_WIDTH;
            //assign dout[prev_ind*DOUT_WIDTH+:ind*DOUT_WIDTH]=concat_temp;   //check!
            assign dout[ind*DOUT_WIDTH-1:prev_ind*DOUT_WIDTH]=concat_temp;   //check!
        end
    end
endgenerate

assign dout_valid = loop_i[0].loop_j[0].temp_dout_valid;

//make the function to calculate the correct index
function automatic [31:0] index_summing;
    input [31:0] in_val;
    input [31:0] max_val;
    begin
        if(in_val==0)begin
            index_summing =max_val;
        end
        else begin
            index_summing = (max_val-in_val)+index_summing(in_val-1, max_val);
        end
    end
endfunction

endmodule
