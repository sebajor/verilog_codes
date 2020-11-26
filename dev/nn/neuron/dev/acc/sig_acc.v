`default_nettype none

//signed accumulator
/*  At the last sample you have to rise the last signal,
the next one you have to lower the last and the en signal
    ie we have one lost cycle in this implementation
    also there is problem with the overflow logic
*/

module sig_acc #(
    parameter DIN_WIDTH = 16,
    parameter DIN_INT = 4,
    parameter DOUT_WIDTH = 32,
    parameter DOUT_INT = 14
) (
    input clk,
    input signed [DIN_WIDTH-1:0] din,
    input en,
    input rst, 
    input last,  //last sample
    output signed [DOUT_WIDTH-1:0] dout,
    output dout_valid
);
    localparam DIN_POINT = DIN_WIDTH-DIN_INT;
    localparam DOUT_POINT = DOUT_WIDTH-DOUT_INT;
    
    reg signed [DOUT_WIDTH-1:0] acc_mem = 0;
    reg valid=0;
    
    //first we need to align the data points...
    //the most typical usage is where dout_point<din_point
    //i didnt test all the configs, only that one!
    //anyways, like is a generate there is not harm in put every option
    
    wire signed [DOUT_WIDTH-1:0] align_din;
    generate 
        if(DOUT_POINT>DIN_POINT)begin
            assign align_din =  din<<<(DOUT_POINT-DIN_POINT);       
        end
        else if(DOUT_POINT<DIN_POINT)begin
            assign align_din = din>>>(DIN_POINT-DOUT_POINT);
        end
        else begin
            assign align_din = din;
        end
    endgenerate

    

    reg signed [DOUT_WIDTH-1:0] acc_combo;
    assign acc_combo = $signed(acc_mem) + $signed(align_din);
    
    //delayed version of acc_combo
    reg signed [DOUT_WIDTH-1:0] d_acc_combo;
    always@(posedge clk)begin
        d_acc_combo <= acc_combo;
    end
    reg flag = 0;//overflow, underflow flag
    always@(posedge clk)begin
        if(rst)begin
            acc_mem <= 0;
            valid <= 0;
            flag <=0;
        end
        else begin
            //check over/under flow
            if(last)begin
                valid <= 1;
                acc_mem <= 0;
                flag <=0;
            end
            else begin
                valid <= 0;
                if(en)begin
                    if(~d_acc_combo[DOUT_WIDTH-1]&~align_din[DOUT_WIDTH-1]&(acc_combo[DOUT_WIDTH-1]))begin
                        //overflow, so we saturate the value
                        flag <=1;
                        acc_mem[DOUT_WIDTH-1] <=1'b0;
                        acc_mem[DOUT_WIDTH-2:0] <= {(DOUT_WIDTH-1){1'b1}};
                    end
                    else if(d_acc_combo[DOUT_WIDTH-1]&align_din[DOUT_WIDTH-1]&(~acc_combo[DOUT_WIDTH-1]))begin
                        //underflow
                        flag <=1;
                        acc_mem[DOUT_WIDTH-1] <= 1'b1;
                        acc_mem[DOUT_WIDTH-2:0] <= {(DOUT_WIDTH-1){1'b0}};
                    end
                    else begin
                        //if in the previous was an over/under flow and the 
                        //sign of data.. dont allow the sum and keep saturate 
                        if(flag & ~(acc_mem[DOUT_WIDTH-1] ^ align_din[DOUT_WIDTH-1]))begin
                            acc_mem <= acc_mem;
                            flag <= 1;
                        end
                        else begin
                            acc_mem <= acc_combo;
                            flag <= 0;
                        end
                    end
                end
                else begin
                    acc_mem <= acc_mem;
                end
            end
        end
    end
    
    reg signed [DOUT_WIDTH-1:0] r_dout=0;
    //check if the final value has over/underflow
    always@(posedge clk)begin
        if(last)begin
            if(acc_mem[DOUT_WIDTH-1]^acc_combo[DOUT_WIDTH-1])
                r_dout <= acc_mem;
            else
                r_dout <= acc_combo;
        end
        else begin
            r_dout <= r_dout;
        end
    end
    
    assign dout = r_dout;//d_acc_combo;
    assign dout_valid = valid;


endmodule 
