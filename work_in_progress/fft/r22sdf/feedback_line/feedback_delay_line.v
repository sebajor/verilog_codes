`default_nettype none

/*
*   Author: sebastian jorquera
*   If Im correct when having high_performance there is a 2 cycle delay when 
*   reading the data.. that means if I am constantly entering data to have a
*   N delay I would need a FIFO_DEPTH = N-2..
*/


module feedback_delay_line #(
    parameter DIN_WIDTH = 16,
    parameter FIFO_DEPTH= 32,
    parameter RAM_PERFORMANCE = "HIGH_PERFORMANCE"
) (
    input wire clk,
    input wire rst,
    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,

    output wire [DIN_WIDTH-1:0] dout,
    output wire dout_valid

);



reg [$clog2(FIFO_DEPTH)-1:0] addr=0;

single_port_ram_read_first #(
  .RAM_WIDTH(DIN_WIDTH),
  .RAM_DEPTH(FIFO_DEPTH),
  .RAM_PERFORMANCE(RAM_PERFORMANCE)
) ram_inst (
  .addra(addr),
  .dina(din),
  .clka(clk),
  .wea(din_valid),
  .ena(1'b1),
  .rsta(1'b0),
  .regcea(1'b1),
  .douta(dout)
);

always@(posedge clk)begin
    if(rst)
        addr <=0;
    else if(din_valid)begin
        if(addr==(FIFO_DEPTH-1))
            addr <= 0;
        else
            addr <= addr+1;
    end
end

reg [1:0] dout_valid_r =0;
always@(posedge clk)begin
    dout_valid_r <= {dout_valid_r[0], din_valid};
end

generate
    if(RAM_PERFORMANCE == "HIGH_PERFORMANCE")
        assign dout_valid = dout_valid_r[1];
    else
        assign dout_valid = dout_valid_r[0];

endgenerate

endmodule
