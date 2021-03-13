`default_nettype none

module adder_tree #(
    parameter DATA_WIDTH = 8,
    parameter PARALLEL = 5
) (
    input clk,
    input [DATA_WIDTH*PARALLEL-1:0] din,
    output [DATA_WIDTH+$clog2(PARALLEL)-1:0] dout
);
generate 
    if(PARALLEL==2)begin
        add #(  .DATA_WIDTH(DATA_WIDTH)) add_inst(
                .clk(clk),
                .din_a(din[DATA_WIDTH-1:0]),
                .din_b(din[DATA_WIDTH+:DATA_WIDTH]),
                .dout(dout)
            );
    end
    else begin
        localparam NEXT_ITER = PARALLEL/2 + PARALLEL%2;
        wire [NEXT_ITER*(DATA_WIDTH+1)-1:0] result;
        add_pairs #(
            .DATA_WIDTH(DATA_WIDTH),
            .STAGE_N(PARALLEL)
        ) add_pairs_inst (
            .clk(clk),
            .din(din),
            .dout(result)
        );
        adder_tree #( .DATA_WIDTH(DATA_WIDTH+1),
        .PARALLEL(NEXT_ITER)) adder_tree_inst(
            .clk(clk),
            .din(result),
            .dout(dout)
        );

    end

endgenerate

endmodule 


module add #(
    parameter DATA_WIDTH = 8
) (
    input clk,
    input signed [DATA_WIDTH-1:0] din_a,
    input signed [DATA_WIDTH-1:0] din_b,
    output signed [DATA_WIDTH:0]  dout
);
    reg [DATA_WIDTH:0] dout_r=0; 
    always@(posedge clk)begin
        dout_r <= din_a + din_b;
    end
    assign dout = dout_r;
endmodule


module add_pairs #(
    parameter DATA_WIDTH = 8,
    parameter STAGE_N = 3
)(
    input clk,
    input [DATA_WIDTH*STAGE_N-1:0] din,
    output [OUT_SIZE*(DATA_WIDTH+1)-1:0] dout
);
    localparam OUT_SIZE = STAGE_N/2+STAGE_N%2;
    genvar i;
    generate
        for(i=0; i<STAGE_N/2; i=i+1)begin
            add #( .DATA_WIDTH(DATA_WIDTH)) add_inst(
                .clk(clk),
                .din_a(din[DATA_WIDTH*2*i+:DATA_WIDTH]),
                .din_b(din[DATA_WIDTH*(2*i+1)+:DATA_WIDTH]),
                .dout(dout[(DATA_WIDTH+1)*i+:DATA_WIDTH+1])
            );
        end
        if(STAGE_N%2==1)begin
            reg [DATA_WIDTH:0] dout_r=0;
            always@(posedge clk)begin
                dout_r <= din[(STAGE_N-1)*DATA_WIDTH+:DATA_WIDTH];
            end 
            assign dout[STAGE_N/2*(DATA_WIDTH+1)+:DATA_WIDTH+1] = dout_r;
            //assign dout[STAGE_N/2*(DATA_WIDTH+1)+:DATA_WIDTH+1] = din[(STAGE_N-1)*DATA_WIDTH+:DATA_WIDTH];
        end
    endgenerate     
endmodule 

