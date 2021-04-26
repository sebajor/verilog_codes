`default_nettype none
`include "bram_infer.v"

module signed_vector_acc #(
    parameter DIN_WIDTH = 32,
    parameter VECTOR_LEN = 64,
    parameter DOUT_WIDTH = 64
) (
    input wire clk,
    input wire new_acc,

    input wire signed [DIN_WIDTH-1:0] din,
    input wire din_valid,

    output wire signed [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);


reg [$clog2(VECTOR_LEN)-1:0] w_addr=0, r_addr=2, acc_count=0;
reg add_zero=0,add_zero_r=0, add_zero_rr=0;
reg dout_valid_r=0;
always@(posedge clk)begin
    if(din_valid)begin
        w_addr <= w_addr+1;
        r_addr <= r_addr+1;
        dout_valid_r <= 0;
        if(add_zero& din_valid)
            acc_count <=acc_count+1;
        //if(add_zero_r)
        if(add_zero_r & din_valid_r)
            dout_valid_r <=1;
    end
    else
        dout_valid_r <=0;
end

always@(posedge clk)begin
    add_zero_r <= add_zero;
    add_zero_rr<=add_zero_r;
    if(new_acc)
        add_zero <=1;
    if(&acc_count)
        add_zero <=0;
end

reg signed [DOUT_WIDTH-1:0] acc=0;
wire signed [DOUT_WIDTH-1:0] bram_out;
reg [$clog2(VECTOR_LEN)-1:0] w_addr_r=0;
reg din_valid_r=0; 
reg signed [DIN_WIDTH-1:0] din_r=0;
always@(posedge clk)begin
    w_addr_r <= w_addr;
    din_valid_r<=din_valid;
    din_r <= din;
    if(din_valid_r)begin
        if(add_zero_rr)
            acc <= din_r;
        else
            acc <= $signed(bram_out)+$signed(din_r);
    end
end



bram_infer #(
    .N_ADDR(VECTOR_LEN),
    .DATA_WIDTH(DOUT_WIDTH)
) bram_imst (
    .clk(clk),
    .wen(din_valid_r), //check!
    .ren(1'b1),
    .wadd(w_addr),
    .radd(r_addr),
    .win(acc),
    .wout(bram_out)
);

assign dout = bram_out;
//assign dout_valid = add_zero&din_valid;//dout_valid_r;
assign dout_valid = dout_valid_r;//dout_valid_r;

endmodule
