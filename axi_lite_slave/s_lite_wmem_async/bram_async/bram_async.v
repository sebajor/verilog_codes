`default_nettype none


module bram_async #(
    parameter DIN_WIDTH = 32,
    parameter N_ADDR = 256,
    parameter INIT_MEM = 1,
    parameter INIT_VALS = "init.hex"

) (
    input wire wclk,
    input wire wen,
    output wire wready,
    input wire [$clog2(N_ADDR)-1:0] waddr,
    input wire [DIN_WIDTH-1:0] win,

    input wire rclk,
    input wire ren,
    input wire [$clog2(N_ADDR)-1:0] raddr,
    output reg [DIN_WIDTH-1:0] rout,
    output wire rvalid
);

generate 
reg [DIN_WIDTH-1:0] mem [N_ADDR-1:0];
if(INIT_MEM==1)begin
    initial begin
        $readmemh(INIT_VALS, mem);        
    end
end
else begin
    integer i;
    initial begin
        for(i=0; i<N_ADDR; i=i+1)begin
            mem[i] =0;
        end
    end
end
endgenerate

//we are going to give priority to the read
//synchronizer of the ren
reg [2:0] ren_wclk=3'b111;
always@(posedge wclk)begin
    ren_wclk <= {ren_wclk[1:0],ren};
end

reg w_ready_r=0;
assign wready =w_ready_r;

always@(posedge wclk)begin
    if(!ren_wclk[2])begin
        w_ready_r <=1;
        if(wen)begin
            mem[waddr] <= win;
        end
    end
    else 
        w_ready_r <=0;
end

reg r_valid_r=0;
assign rvalid =r_valid_r;

always@(posedge rclk)begin
    if(ren)begin
        rout <= mem[raddr];
        r_valid_r <=1'b1;
    end
    else
        r_valid_r <=1'b0;
end

endmodule
