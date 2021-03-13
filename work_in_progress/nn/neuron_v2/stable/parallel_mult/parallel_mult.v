`default_nettype none

module parallel_mult #(
    parameter PARALLEL_IN = 4,
    parameter DATA1_WIDTH = 16,
    parameter DATA1_INT = 2,
    parameter DATA2_WIDTH = 16,
    parameter DATA2_INT = 2,
    parameter OUT_WIDTH = 32,
    parameter OUT_INT = 4
) (
    input wire clk,
    input wire [DATA1_WIDTH*PARALLEL_IN-1:0] din1,
    input wire [DATA2_WIDTH*PARALLEL_IN-1:0] din2,
    input wire sync_in,
    output wire sync_out,
    output wire [OUT_WIDTH*PARALLEL_IN-1:0] dout
);
    genvar i;
    generate
        for(i=0; i<PARALLEL_IN; i=i+1)begin
            single_mult #(
                .DATA1_WIDTH(DATA1_WIDTH),
                .DATA1_INT(DATA1_INT),
                .DATA2_WIDTH(DATA2_WIDTH),
                .DATA2_INT(DATA2_INT),
                .OUT_WIDTH(OUT_WIDTH),
                .OUT_INT(OUT_INT)
            ) mult_inst (
                .clk(clk),
                .din1(din1[DATA1_WIDTH*i+:DATA1_WIDTH]),
                .din2(din2[DATA2_WIDTH*i+:DATA2_WIDTH]),
                .dout(dout[OUT_WIDTH*i+:OUT_WIDTH])
            );
        end
    endgenerate
    
    reg [2:0] sync_dly = 0;
    always@(posedge clk)begin
        sync_dly <= {sync_dly[1:0], sync_in}; 
    end
endmodule


module single_mult (
    parameter DATA1_WIDTH = 16,
    parameter DATA1_INT = 2,
    parameter DATA2_WIDTH = 16,
    parameter DATA2_INT = 2,
    parameter OUT_WIDHT = 32,
    parameter OUT_INT = 4
) (
    input wire clk,
    input wire [DATA1_WIDTH-1:0] din1,
    input wire [DATA2_WIDHT-1:0] din2,
    output wire [OUT_WIDTH-1:0] dout
);




endmodule 
