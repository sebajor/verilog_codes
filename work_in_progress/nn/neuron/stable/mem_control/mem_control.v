`default_nettype none
`include "../Weights_mem/Weigth_mem.v"
`define "_pretrained_"


//it has a 2 cycles delay

module mem_control #(
    parameter ADDR = 256,
    parameter DOUT_WIDTH = 16,
    parameter WEIGHT_FILE = "weight_test.mem"
) (
    input clk,
    input rst,
    input valid,
    output [DOUT_WIDTH-1:0] dout,
    output dout_valid
);


reg [$clog2(ADDR)-1:0] addr_counter = 0;
reg ren=0;
always@(posedge clk)begin
    if(rst)begin
        addr_counter <= {($clog2(ADDR)){1'b1}}; //to be in zero with the first
                                              // valid signal
        ren <= 0;
    end
    else begin
        if(valid)begin
            addr_counter <= addr_counter +1;
            ren <= 1;
        end
        else begin
            addr_counter <= addr_counter;
            ren <= ren;
        end
    end
end

reg [DOUT_WIDTH-1:0] dout_r;

Weight_mem #(
    .N_WEIGHT(ADDR),
    .DATA_WIDTH(DOUT_WIDTH),
    .WEIGHT_FILE(WEIGHT_FILE)
) weight_mem_inst (
    .clk(clk),
    .wen(1'b0),
    .ren(ren),
    .wadd(),
    .radd(addr_counter),
    .win(),
    .wout(dout_r)
);

//delay for the valid signal
reg ren_r = 0;
always@(posedge clk)begin
    if(rst)
        ren_r <= 0;
    else
        ren_r <= ren;
end


assign dout = dout_r;
assign dout_valid = ren_r;

endmodule
