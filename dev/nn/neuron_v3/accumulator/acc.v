`default_nettype none
`ifndef _ACC_
    `define _ACC_
`endif


/* signed accumulator 
*/

module acc #(
    parameter DIN_WIDTH = 16,
    parameter DIN_INT= 4,
    parameter DOUT_WIDTH = 32,
    parameter DOUT_INT = 14 
) (
    input wire clk,
    input wire rst,
    input wire signed [DIN_WIDTH-1:0] din,
    input wire din_valid,
    input wire din_sof,
    input wire din_eof,
    output wire signed [DOUT_WIDTH-1:0] dout,
    output wire dout_valid 
);

localparam DIN_POINT = DIN_WIDTH-DIN_INT;
localparam DOUT_POINT = DOUT_WIDTH-DOUT_INT;


//point alignment between input data and the accumulated one
//this only depend on the parameters 
wire signed [DOUT_WIDTH-1:0] align_din;
generate 
if(DOUT_POINT>DIN_POINT)
    assign align_din = din<<<(DOUT_POINT-DIN_POINT);
else if(DOUT_POINT<DIN_POINT)
    assign  align_din = din>>>(DIN_POINT-DOUT_POINT);
else
    assign align_din = din;
endgenerate

reg signed [DOUT_WIDTH-1:0] acc_mem = 0;
reg valid =0;


//we want to detect over/underflow so when the flag is up
//0: everything is good, 1: overflow, 2:underflow
reg [1:0] flag =0;


always@(posedge clk)begin
    if(rst)begin
        valid <= 0;
        acc_mem <=0;
    end
    else begin
        if(din_valid)begin
            if(din_sof)begin
                acc_mem <= align_din;
                valid <= 0;
            end
            else if(din_eof)begin
                acc_mem <= acc_mem+align_din;
                valid <= 1;
            end
            else begin
                acc_mem <= acc_mem+align_din;
            end
        end
    end
end

//over/underflow flag logic
//check the previous acc_mem
reg prev_sign_acc=0;
reg prev_sign_din=0;
reg prev_sof =0;
always@(posedge clk)begin
    prev_sign_acc <= acc_mem[DOUT_WIDTH-1];
    prev_sign_din <= din[DIN_WIDTH-1];
    prev_sof <= din_sof;
end

always@(posedge clk)begin
    if(rst)
        flag <=0;
    else if(din_valid)begin
        //we reset the flag after 1 word (is impossible to have an overflow there)
        if(prev_sof)
            flag <=0;
        else begin
            //overflow, also if any flag is rised we keep the first over/underflow
            if((acc_mem[DOUT_WIDTH-1]&(~prev_sign_acc&~prev_sign_din))&~(|flag))
                flag[0]<=1'b1;
            else if((~acc_mem[DOUT_WIDTH-1] &(prev_sign_acc&prev_sign_din))&~(|flag))
                flag[1]<=1'b1;
            else
                flag <= flag;
        end
    end 
end

//after the eof we have one cycle to check if there was an overflow
//so after 2 cycles of eof we have available a valid output

reg signed [DOUT_WIDTH-1:0] dout_r=0, acc_mem_r=0;
reg valid_r=0, valid_rr=0;
always@(posedge clk)begin
    valid_r <= valid;
    valid_rr <= valid_r;
    acc_mem_r <= acc_mem;
    //the check takes one cycle, 
    if(valid_r)begin
        if(flag[0])begin
            //overflow
            dout_r <= {1'b0, {(DOUT_WIDTH-1){1'b1}}}; 
        end
        else if(flag[1])begin
            //underflow
            dout_r <= {1'b1, {(DOUT_WIDTH-1){1'b0}}};
        end
        else
            dout_r <= acc_mem_r;
    end
    else begin
        dout_r <= dout_r;
    end 
end





assign dout = dout_r;
assign dout_valid = valid_rr; 


endmodule
