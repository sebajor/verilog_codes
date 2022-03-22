
module pkt_gen #(
    parameter DOUT_WIDTH = 32,
    parameter PARALLEL = 4
) (
    input wire clk,
    input wire en,
    input wire rst,

    input wire [31:0] burst_len,
    input wire [31:0] sleep_write,

    output wire [DOUT_WIDTH*PARALLEL-1:0] dout,
    output wire dout_valid
);

genvar i;
generate 

for(i=0; i< PARALLEL; i=i+1)begin: for_loop

//reg [DOUT_WIDTH-1:0] counter =0;
reg [31:0] counter=0;
reg dout_valid_r=0;
reg state=1;
reg [31:0] cycles_count=0;
always@(posedge clk)begin
    if(rst)begin
        dout_valid_r <=0;
        counter <=0;
        state <=1;
    end
    else if(en)begin
        if(state==0)begin
            if(cycles_count==burst_len)begin
                cycles_count <=0;
                counter <=i;
                dout_valid_r <=0;
                state <=1;
            end
            else begin 
                counter <= counter+PARALLEL;
                cycles_count <= cycles_count +1;
                dout_valid_r <=1;
            end
        end
        else begin
            if(cycles_count==sleep_write)begin
                dout_valid_r <=1;
                counter <=32'haabbccdd;
                cycles_count <=0;
            end
            else if((counter == 32'haabbccdd) & (cycles_count==0))begin
                state <=0;
                counter <=i;
            end
            else begin
                cycles_count <= cycles_count+1;
                dout_valid_r <=0;
            end
        end
    end
end

assign dout[DOUT_WIDTH*i+:DOUT_WIDTH]=counter[DOUT_WIDTH-1:0];
end 



endgenerate

assign dout_valid = for_loop[PARALLEL-1].dout_valid_r;

endmodule
