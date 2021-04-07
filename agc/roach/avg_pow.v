`default_nettype none
`include "adder_tree.v"
`include "parallel_mult.v"
`include "moving_average_unsign.v"

/*
    takes parallel samples, square them add it and thats the 
    input value for a moving average module
*/

module avg_pow #(
    parameter DIN_WIDTH = 8,
    parameter PARALLEL = 8,
    parameter DELAY_LINE = 16,
    parameter APROX = "nearest" //nearest, truncate
) (
    input wire clk,
    input wire rst,
    
    input wire [DIN_WIDTH*PARALLEL-1:0] din,
    input wire din_valid,

    //output wire [2*DIN_WIDTH+$clog2(PARALLEL)-1:0] dout,
    output wire [2*DIN_WIDTH-1:0] dout,
    output wire dout_valid
);

//to improve timing
reg [DIN_WIDTH*PARALLEL-1:0] din1=0, din2=0;
reg din_valid_dly=0;
always@(posedge clk)begin
    din1 <= din;
    din2 <= din;
    din_valid_dly <= din_valid;
end

wire [2*DIN_WIDTH*PARALLEL-1:0] din_pow;
wire [PARALLEL-1:0] din_pow_valid;

parallel_mult #(
    .PARALLEL(PARALLEL),
    .DIN1_WIDTH(DIN_WIDTH),
    .DIN2_WIDTH(DIN_WIDTH),
    .DOUT_WIDTH(2*DIN_WIDTH)
) din_pow_inst (
    .clk(clk),
    .din1(din1),
    .din2(din2),
    .din_valid(din_valid_dly),
    .dout(din_pow),
    .dout_valid(din_pow_valid)
);


wire [2*DIN_WIDTH+$clog2(PARALLEL)-1:0] pow_add;
wire pow_add_valid;

adder_tree #(
    .DATA_WIDTH(2*DIN_WIDTH),
    .PARALLEL(PARALLEL)
)adder_tree_inst (
    .clk(clk),
    .din(din_pow),
    .in_valid(din_pow_valid[0]),
    .dout(pow_add),
    .out_valid(pow_add_valid)
);


wire [2*DIN_WIDTH+$clog2(PARALLEL)-1:0] avg_din_pow;
wire avg_din_pow_valid;

moving_average_unsign #(
    .DIN_WIDTH(2*DIN_WIDTH+$clog2(PARALLEL)),
    .DIN_POINT(2*DIN_WIDTH-1),
    .WINDOW_LEN(DELAY_LINE),
    .DOUT_WIDTH(2*DIN_WIDTH+$clog2(PARALLEL)),
    .APPROX("truncate")   //truncate, nearest
) mov_avg_inst (
    .clk(clk),
    .rst(rst),
    .din(pow_add),
    .din_valid(pow_add_valid),
    .dout(avg_din_pow),
    .dout_valid(avg_din_pow_valid)
);

//normalize by the parallel inputs
//


generate 
if(APROX=="truncate")
    assign dout = avg_din_pow[2*DIN_WIDTH+$clog2(PARALLEL)-1-:2*DIN_WIDTH];
else if(APROX=="nearest")
    assign dout = avg_din_pow[$clog2(PARALLEL)-1:0]>{1'b0,{(PARALLEL-1){1'b1}}} ? 
    (avg_din_pow[2*DIN_WIDTH+$clog2(PARALLEL)-1-:2*DIN_WIDTH]+1):
                            (avg_din_pow[2*DIN_WIDTH+$clog2(PARALLEL)-1-:2*DIN_WIDTH]);
else
    assign dout = avg_din_pow[DIN_WIDTH+$clog2(PARALLEL)-1-:DIN_WIDTH];
endgenerate


//assign dout = avg_din_pow;
assign dout_valid = avg_din_pow_valid;



endmodule
