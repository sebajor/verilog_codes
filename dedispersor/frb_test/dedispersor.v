`default_nettype none
`include "dedispersor_block.v"

//this is serial dedispersor ie it gets the FFT channels 
//sequentially

module dedispersor #(
    parameter N_CHANNELS=8, //pow of 2
    parameter [32*N_CHANNELS-1:0] DELAY_ARRAY = {32'd2,32'd3,32'd4,32'd5,32'd6,32'd7,32'd8,32'd9}, //ch8,ch7,...ch0
    parameter DIN_WIDTH = 32
) (
    input wire clk,
    input wire ce,
    input wire rst,
    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,
    output wire [DIN_WIDTH-1:0] dout,
    output wire dout_valid,

    output wire dout_sof,
    output wire dout_eof
);

reg [$clog2(N_CHANNELS)-1:0] addr_counter=0;
always@(posedge clk)begin
    if(rst)
        addr_counter <=0;
    else if(din_valid)
        addr_counter <= addr_counter+1;
    else
        addr_counter <= addr_counter;
end

//check!!
reg dout_sof_r=0, dout_eof_r=0;
always@(posedge clk)begin
    dout_sof_r <= (addr_counter==0)&& din_valid;
    dout_eof_r <= (addr_counter==(N_CHANNELS-1))&&din_valid;
end
assign dout_sof = dout_sof_r;
assign dout_eof = dout_eof_r;

genvar i;

wire [N_CHANNELS*DIN_WIDTH-1:0] dout_block;
wire [N_CHANNELS-1:0] dout_block_valid;
generate
for(i=0; i<N_CHANNELS; i=i+1)begin: dedispersor_loop
    //wire valid_block;
    //assign valid_block = ((addr_counter==i) && din_valid);
    reg valid_block=0;
    reg [DIN_WIDTH-1:0] din_block=0;
    always@(posedge clk)begin
        valid_block <= (addr_counter==i) && din_valid;
        din_block <= din;
    end
    
    wire [DIN_WIDTH-1:0] dout_block_stage;
    wire dout_block_stage_val; 

    dedispersor_block #(
        .DELAY_LINE(DELAY_ARRAY[32*i+:32]),
        .DIN_WIDTH(DIN_WIDTH)
    ) dedispersor_block_inst (
        .clk(clk),
        .ce(ce),
        .rst(rst),
        .din(din_block),
        .din_valid(valid_block),
        .dout(dout_block_stage),//dout_block[DIN_WIDTH*i+:DIN_WIDTH]),
        .dout_valid(dout_block_stage_val)//dout_block_valid[i])
    );
    
    //pipelined the output
        
    reg [DIN_WIDTH-1:0] dout_block_stage_r=0;
    reg dout_block_val_r=0;
    always@(posedge clk)begin
        dout_block_stage_r <= dout_block_stage;
        dout_block_val_r <= dout_block_stage_val;
    end
    assign dout_block[DIN_WIDTH*i+:DIN_WIDTH]= dout_block_stage_r;
    assign dout_block_valid[i]=dout_block_val_r;

end

endgenerate 

reg [DIN_WIDTH-1:0] dout_r=0;
reg dout_valid_r=0;
assign dout = dout_r;
assign dout_valid = dout_valid_r;

/*
//should be changed manually... uff
//check resource usage to decide 
always@(posedge clk)begin
    dout_valid_r <= |dout_block_valid;
    if(|dout_block_valid)begin
        case(dout_block_valid)
            32'd1:  dout_r<= dout_block[0+:DIN_WIDTH];
            32'd2:  dout_r<= dout_block[DIN_WIDTH+:DIN_WIDTH];
            32'd4:  dout_r<= dout_block[2*DIN_WIDTH+:DIN_WIDTH];
            32'd8:  dout_r<= dout_block[3*DIN_WIDTH+:DIN_WIDTH];
            32'd16:  dout_r<= dout_block[4*DIN_WIDTH+:DIN_WIDTH];
            32'd32:  dout_r<= dout_block[5*DIN_WIDTH+:DIN_WIDTH];
            32'd64:  dout_r<= dout_block[6*DIN_WIDTH+:DIN_WIDTH];
            32'd128:  dout_r<= dout_block[7*DIN_WIDTH+:DIN_WIDTH];
            default: dout_r <=0;
    endcase
end

end
*/


integer j;
always@(posedge clk)begin
    //default value
    dout_valid_r = 1'b0;
    dout_r = dout_r;   
    for(j=0; j<N_CHANNELS; j=j+1)begin
        if(dout_block_valid[j]==1)begin
            dout_r = dout_block[DIN_WIDTH*j+:DIN_WIDTH];
            dout_valid_r=1'b1;
        end
    end
end




endmodule 
