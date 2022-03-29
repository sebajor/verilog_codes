`default_nettype none

/*
*   Based in https://github.com/projf/projf-explore/blob/main/lib/maths/sqrt.sv
*   It takes (DIN_WIDTH+DIN_POINT)/2 cycles to have a valid output
*/

module iterative_sqrt #(
    parameter DIN_WIDTH = 8,
    parameter DIN_POINT = 6
) (
    input wire clk,
    output wire busy,
    input wire din_valid,
    input wire [DIN_WIDTH-1:0] din,
    output wire [DIN_WIDTH-1:0] dout,
    output wire [DIN_WIDTH-1:0] reminder,
    output wire dout_valid
);

generate 

if(DIN_POINT==0)begin
    localparam ITERS = DIN_WIDTH/2;
    reg [$clog2(ITERS)-1:0] iter_count=0;


    reg [DIN_WIDTH-1:0] x=0, x_next=0;      //din_value
    reg [DIN_WIDTH-1:0] quot=0, quot_next=0;//quotient
    reg [DIN_WIDTH+1:0] acc=0, acc_next=0;  //accumulator
    reg [DIN_WIDTH+1:0] res=0;              //preliminal results 


    always@(*)begin
        res = acc - {quot, 2'b01};
        if(~res[DIN_WIDTH+1])begin
            {acc_next, x_next} = {res[DIN_WIDTH-1:0], x, 2'b0};
            quot_next = {quot[DIN_WIDTH-2:0], 1'b1};
        end
        else begin
            {acc_next, x_next} = {acc[DIN_WIDTH-1:0],x,2'b0};
            quot_next = quot<<1;
        end
    end


    reg busy_r=0, dout_valid_r=0;
    reg [DIN_WIDTH-1:0] dout_r=0, reminder_r=0;

    assign busy = busy_r;
    assign dout_valid = dout_valid_r;
    assign dout = dout_r;
    assign reminder = reminder_r;

    always@(posedge clk)begin
        if(din_valid & ~busy_r)begin
            busy_r <=1;
            dout_valid_r <=0;
            iter_count <=0;
            quot <=0;
            {acc, x} <= {{DIN_WIDTH{1'b0}}, din, 2'b0};
        end
        else if(busy_r)begin
            if(iter_count == (ITERS-1))begin
                iter_count <=0;
                busy_r <=0;
                dout_valid_r <=1;
                dout_r <= quot_next;
                reminder_r <= acc_next[DIN_WIDTH+1:2]; //undo the previous shift
            end
            else begin
                dout_valid_r <=0;
                iter_count <= iter_count+1;
                x <= x_next;
                acc <= acc_next;
                quot <= quot_next;
            end
        end
        else begin
            busy_r <=0;
            dout_valid_r <=0;
        end 
    end

end
else begin
    localparam ITERS = (DIN_WIDTH+DIN_POINT)/2;
    reg [$clog2(ITERS)-1:0] iter_count=0;


    reg [DIN_WIDTH-1:0] x=0, x_next=0;      //din_value
    reg [DIN_WIDTH-1:0] quot=0, quot_next=0;//quotient
    reg [DIN_WIDTH+1:0] acc=0, acc_next=0;  //accumulator
    reg [DIN_WIDTH+1:0] res=0;              //preliminal results 


    always@(*)begin
        res = acc - {quot, 2'b01};
        if(~res[DIN_WIDTH+1])begin
            {acc_next, x_next} = {res[DIN_WIDTH-1:0], x, 2'b0};
            quot_next = {quot[DIN_WIDTH-2:0], 1'b1};
        end
        else begin
            {acc_next, x_next} = {acc[DIN_WIDTH-1:0],x,2'b0};
            quot_next = quot<<1;
        end
    end


    reg busy_r=0, dout_valid_r=0;
    reg [DIN_WIDTH-1:0] dout_r=0, reminder_r=0;

    assign busy = busy_r;
    assign dout_valid = dout_valid_r;
    assign dout = dout_r;
    assign reminder = reminder_r;

    always@(posedge clk)begin
        if(din_valid & ~busy_r)begin
            busy_r <=1;
            dout_valid_r <=0;
            iter_count <=0;
            quot <=0;
            {acc, x} <= {{DIN_WIDTH{1'b0}}, din, 2'b0};
        end
        else if(busy_r)begin
            if(iter_count == (ITERS-1))begin
                iter_count <=0;
                busy_r <=0;
                dout_valid_r <=1;
                dout_r <= quot_next;
                reminder_r <= acc_next[DIN_WIDTH+1:2]; //undo the previous shift
            end
            else begin
                dout_valid_r <=0;
                iter_count <= iter_count+1;
                x <= x_next;
                acc <= acc_next;
                quot <= quot_next;
            end
        end
        else begin
            busy_r <=0;
            dout_valid_r <=0;
        end 
    end
end

endgenerate


endmodule


