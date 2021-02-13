`default_nettype none 

/*the idea is to save a one frame into a bram
and then read it using axi-lite 
*/

module save_frame (
    //camera data
    input wire pclk,
    input wire pxl_valid,
    input wire frame_done,
    input wire [15:0] pdata,
    input wire [18:0] pxl_addr,

    //read data
    input wire en_save,
    input wire rst,
    input wire r_clk,
    input wire [18:0] read_addr,
    output wire [15:0] pxl_r_data,
    output wire pxl_r_valid
);

reg [15:0] mem [640*480-1:0];


//cross clock domains
reg [3:0] rst_r = 4'b0;
reg [3:0] en_save_r = 4'b0;

always@(posedge pclk)begin
    rst_r <= {rst_r[2:0], rst};
    en_save_r <= {en_save_r[2:0], en_save};
end

//read side 
reg [15:0] read_data = 0;
always@(posedge r_clk)begin
    read_data <= mem[read_addr];
end

//write side
reg sof = 0;
reg finish =0;
always@(posedge pclk)begin
    if(rst_r[3])begin
        sof <= 0;
        finish <=0;
    end
    else begin
        sof <= (en_save_r[3] && frame_done);
    end
end

always@(posedge pclk)begin
    if(sof && pxl_valid)begin
        mem[pxl_addr] <= pdata;
    end
end

endmodule 
