`default_nettype none
//`include "rom.v"
/*
    arctan based in cordic algorithm. The output is 1/pi*arctan2(y,x)
    so the output lives in -1,1
    this module takes DIN_WIDTH cycles to output one value
    
    also this module is just in the first quadrant, could be extended using
    trigronometic relations.
*/

module arctan #(
    parameter DIN_WIDTH = 16,
    parameter DOUT_WIDTH = 16,
    parameter ROM_FILE ="atan_rom.hex"
) ( 

    input wire clk,
    input wire [DIN_WIDTH-1:0] y,x,
    input wire din_valid,

    output wire sys_ready,
    output wire signed [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);

reg [$clog2(DIN_WIDTH)-1:0] counter=0, count_shift=0;
reg busy=0;
always@(posedge clk)begin
    if(din_valid & ~busy)
        busy <= 1;
    else if(busy)begin
        if((counter==(DIN_WIDTH-1)) | (y_reg==0 & counter!=0))
            busy <= 0;
        else
            busy <= 1;
    end
    else
        busy <= busy;
end

//rom to save the arctan(2**-i)
wire signed [DOUT_WIDTH-1:0] rom_val;

rom #(
    .N_ADDR(DIN_WIDTH),
    .DATA_WIDTH(DOUT_WIDTH),
    .INIT_VALS(ROM_FILE)
) atan_rom (
    .clk(clk),
    .ren(1'b1),
    .radd(counter),
    .wout(rom_val)
);



always@(posedge clk)begin
    if(busy)begin
        if(counter==DIN_WIDTH)begin
            counter <=0;
            count_shift <= 0;
        end
        else begin
            count_shift <= count_shift+1;
            counter <= counter+1;
        end
    end
    else if(din_valid & ~busy)
        counter <= 1;
    else begin
        counter <= 0;
        count_shift <= 0;
    end
end 

//update the values
reg debug=0;
reg signed [DOUT_WIDTH:0] x_reg=0, y_reg=0, z_reg=0;
always@(posedge clk)begin
    if(din_valid & ~busy)begin
        x_reg <= x; y_reg <= y; z_reg <= 0;
    end
    else if(busy)begin
        if(~y_reg[DOUT_WIDTH] | (counter==0))begin
            debug <=0;
            x_reg <= $signed(x_reg)+$signed(y_reg>>>count_shift);
            y_reg <= $signed(y_reg)-$signed(x_reg>>>count_shift);
            z_reg <= $signed(z_reg)+$signed(rom_val);
        end
        else begin
            debug <= 1;
            x_reg <= $signed(x_reg)-$signed(y_reg>>>count_shift);
            y_reg <= $signed(y_reg)+$signed(x_reg>>>count_shift);
            z_reg <= $signed(z_reg)-$signed(rom_val);
        end
    end
    else begin
        x_reg <=0; y_reg <=0;z_reg <=z_reg;
    end
end


reg [DOUT_WIDTH-1:0] dout_r=0;
reg dout_valid_r=0;
wire algo_end1 = (counter==DIN_WIDTH-1);
wire algo_end2 = y_reg==0 & (counter!=0) & busy;
always@(posedge clk)begin
    //if((counter==(DIN_WIDTH-1)) | (y_reg==0 & counter!=0))begin
    if(algo_end1 | algo_end2)begin
        dout_r <= z_reg;
        dout_valid_r <= 1'b1;
    end
    else begin
        dout_r <= dout_r;
        dout_valid_r <= 1'b0;
    end
end

assign dout = dout_r;
assign dout_valid = dout_valid_r;
assign sys_ready = ~busy;


endmodule
