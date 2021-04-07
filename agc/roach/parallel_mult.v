`default_nettype none

//previous this block handle the bit point alignment

module parallel_mult #(
    parameter PARALLEL = 4,
    parameter DIN1_WIDTH = 16,
    parameter DIN2_WIDTH = 16,
    parameter DOUT_WIDTH = 32
) (
    input wire clk,
    input wire [DIN1_WIDTH*PARALLEL-1:0] din1,
    input wire [DIN2_WIDTH*PARALLEL-1:0] din2,
    input wire din_valid,
    output wire [DOUT_WIDTH*PARALLEL-1:0] dout,
    output wire [PARALLEL-1:0] dout_valid
);
genvar i;
generate 
    for(i=0; i<PARALLEL; i=i+1)begin
        dsp48_mult #(
            .DIN1_WIDTH(DIN1_WIDTH),
            .DIN2_WIDTH(DIN2_WIDTH),
            .DOUT_WIDTH(DOUT_WIDTH)
        ) dsp48_mult_inst (
            .clk(clk),
            .din1(din1[DIN1_WIDTH*i+:DIN1_WIDTH]),
            .din2(din2[DIN2_WIDTH*i+:DIN2_WIDTH]),
            .din_valid(din_valid),
            .dout(dout[DOUT_WIDTH*i+:DOUT_WIDTH]),
            .dout_valid(dout_valid[i])
        );
    end
endgenerate


endmodule 

//infers a dsp48 multiplier
module dsp48_mult #(
    parameter integer DIN1_WIDTH = 16,
    parameter integer DIN2_WIDTH = 16,
    parameter integer DOUT_WIDTH = 32
) (
    input wire clk,
    input wire [DIN1_WIDTH-1:0] din1,
    input wire [DIN2_WIDTH-1:0] din2,
    input wire din_valid,
    
    output wire [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);
/*  the dsp48e1 has 3 registers.. two at the input and one at the
    output
*/
reg [DIN1_WIDTH-1:0] din1_reg_0=0, din1_reg_1=0;
reg [DIN2_WIDTH-1:0] din2_reg_0=0, din2_reg_1=0;

reg [DOUT_WIDTH-1:0] dout_reg_0=0, dout_reg_1=0;
reg [3:0] dout_valid_r=0;


assign dout = dout_reg_1;
assign dout_valid = dout_valid_r[3];


always@(posedge clk)begin
    dout_valid_r[1] <= dout_valid_r[0];
    dout_valid_r[2] <= dout_valid_r[1]; 
    dout_valid_r[3] <= dout_valid_r[2];
    if(din_valid)begin
        din1_reg_0 <= din1;
        din2_reg_0 <= din2;
        dout_valid_r[0] <= 1'b1;
    end
    else begin
        dout_valid_r[0] <= 1'b0;
        din1_reg_0 <= 0;
        din2_reg_0 <= 0;
    end
end

always@(posedge clk)begin
    din1_reg_1 <= din1_reg_0;
    din2_reg_1 <= din2_reg_0;
    dout_reg_0 <= $signed(din1_reg_1)*$signed(din2_reg_1);
    dout_reg_1 <= dout_reg_0;
end

endmodule


