`default_nettype none

//the adder tree has some sort of recursive call back structure
//maybe the compiler doesnt like it..
module adder_tree #(
    parameter DATA_WIDTH = 8,
    parameter PARALLEL = 10
) (
    input wire clk,
    input wire [DATA_WIDTH*PARALLEL-1:0] din,
    input wire in_valid,
    output wire [DATA_WIDTH+$clog2(PARALLEL)-1:0] dout,
    output wire out_valid
);
generate
    if(PARALLEL==2)begin
        signed_adder #(.DATA_WIDTH(DATA_WIDTH)) sign_adder_inst (
                .clk(clk),
                .din1(din[DATA_WIDTH-1:0]),
                .din2(din[DATA_WIDTH+:DATA_WIDTH]),
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
        adder_tree #( .DATA_WIDTH(DATA_WIDTH+1),.PARALLEL(NEXT_ITER)) 
            adder_tree_inst(
                .clk(clk),
                .din(result),
                .dout(dout)
            );
    end
endgenerate

//valid signal delay
reg [$clog2(PARALLEL)+PARALLEL%2-1:0] delay_valid=0;
always@(posedge clk)begin
    delay_valid <= {delay_valid[$clog2(PARALLEL)+PARALLEL%2:0], in_valid}; 
end

assign out_valid = delay_valid[$clog2(PARALLEL)+PARALLEL%2-1];


endmodule


module signed_adder #(
    parameter DATA_WIDTH = 8
) (
    input wire clk,
    input wire signed [DATA_WIDTH-1:0] din1,
    input wire signed [DATA_WIDTH-1:0] din2,
    output wire signed [DATA_WIDTH:0] dout
);
    reg [DATA_WIDTH:0] dout_r =0;
    always@(posedge clk)begin
        dout_r <= $signed(din1)+$signed(din2);
    end
    assign dout = dout_r;
endmodule


module add_pairs #(
    parameter DATA_WIDTH = 8,
    parameter STAGE_N = 3
) (
    input wire clk,
    input wire [DATA_WIDTH*STAGE_N-1:0] din,
    output wire [OUT_WIDTH*(DATA_WIDTH+1)-1:0] dout
);
localparam OUT_WIDTH = STAGE_N/2+STAGE_N%2;
genvar i;
generate 
    for(i=0; i<STAGE_N/2; i=i+1)begin
        signed_adder #(.DATA_WIDTH(DATA_WIDTH)) add_inst (
            .clk(clk),
            .din1(din[DATA_WIDTH*2*i+:DATA_WIDTH]),
            .din2(din[DATA_WIDTH*(2*i+1)+:DATA_WIDTH]),
            .dout(dout[(DATA_WIDTH+1)*i+:DATA_WIDTH+1])
        );
    end
    if(STAGE_N%2==1)begin
        //if the stage its not even
        reg [DATA_WIDTH:0] dout_r =0;
        always@(posedge clk)begin
            dout_r <= din[(STAGE_N-1)*DATA_WIDTH+:DATA_WIDTH];
        end
        assign dout[STAGE_N/2*(DATA_WIDTH+1)+:DATA_WIDTH+1] = dout_r;
    end
endgenerate
endmodule



