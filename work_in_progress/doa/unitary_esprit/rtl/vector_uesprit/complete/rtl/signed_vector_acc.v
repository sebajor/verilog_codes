`default_nettype none
//`include "bram_infer.v"

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

reg [$clog2(VECTOR_LEN)-1:0] w_addr=0, r_addr=1, acc_count=0;
reg add_zero=0;
reg din_valid_r=0;
always@(posedge clk)begin
    din_valid_r <= din_valid;
    if(din_valid)begin
        r_addr <= r_addr+1;
    end
end


always@(posedge clk)begin
    if(new_acc)
        add_zero<=1;
    if(add_zero && (&acc_count))
        add_zero <=0;
end

always@(posedge clk)begin
    if(~add_zero)
        acc_count <= 0;
    else if(din_valid_r && add_zero)
        acc_count <= acc_count+1;
    else
        acc_count <= acc_count;
end

reg signed [DOUT_WIDTH-1:0] acc=0;
wire signed [DOUT_WIDTH-1:0] bram_out;
reg dout_valid_r =0; 
reg [DIN_WIDTH-1:0] din_r =0;
always@(posedge clk)begin
    din_r <= din;
    if(din_valid_r) begin
        if(add_zero) begin
            w_addr <= w_addr+1;
            acc <= $signed(din_r);
            dout_valid_r <= 1;
        end
        else begin
            w_addr <= w_addr+1;
            acc <= $signed(bram_out)+$signed(din_r);
            dout_valid_r <=0;
        end
    end
    else 
        dout_valid_r <= 0;
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
assign dout_valid = din_valid_r && add_zero;//dout_valid_r;

endmodule
