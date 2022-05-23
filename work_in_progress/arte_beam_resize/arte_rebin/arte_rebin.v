`default_nettype none

module arte_rebin #(
    parameter DIN_WIDTH = 32,
    parameter DIN_POINT = 20,
    parameter FFT_CHANNEL =2048,
    parameter PARALLEL = 4,
    parameter INPUT_DELAY = 0,
    parameter OUTPUT_DELAY =0,
    parameter DEBUG=1
)(
    input wire clk,
    input wire cnt_rst,

    input wire sync_in,
    input wire [DIN_WIDTH*PARALLEL-1:0] power_resize,

    output wire [DIN_WIDTH+$clog2(PARALLEL)+1:0] dout,
    output wire dout_valid
);


wire [DIN_WIDTH*PARALLEL-1:0] power_resize_r;
wire sync_in_r;

delay #(
    .DATA_WIDTH(DIN_WIDTH*PARALLEL+1),
    .DELAY_VALUE(INPUT_DELAY)
) input_delay_inst (
    .clk(clk),
    .din({power_resize, sync_in}),
    .dout({power_resize_r, sync_in_r})
);

wire [DIN_WIDTH+$clog2(PARALLEL)-1:0] adder_tree_dout;
wire sync_adder;


adder_tree #(
    .DATA_WIDTH(DIN_WIDTH),
    .PARALLEL(PARALLEL),
    .DATA_TYPE("unsigned")
) adder_tree_inst (
    .clk(clk),
    .din(power_resize),
    .din_valid(sync_in),
    .dout(adder_tree_dout),
    .dout_valid(sync_adder)
);


//check!
reg acc_valid_in=0;
always@(posedge clk)begin
    if(cnt_rst)
        acc_valid_in <=0;
    else if(sync_adder)
        acc_valid_in <= 1;
end


reg [2:0] acc_counter=0;
always@(posedge clk)begin
    if(cnt_rst)
        acc_counter <=0;
    else if(&acc_counter | sync_adder)
        acc_counter <= 0;
    else
        acc_counter <= acc_counter+1;
end

wire acc_ready = (acc_counter == 7);
wire [DIN_WIDTH+1+$clog2(PARALLEL):0] acc_data;
wire acc_valid;

scalar_accumulator #(
    .DIN_WIDTH(DIN_WIDTH+$clog2(PARALLEL)),
    .ACC_WIDTH(DIN_WIDTH+$clog2(PARALLEL)+2),
    .DATA_TYPE("unsigned")
) scalar_accumulator_inst (
    .clk(clk),
    .din(adder_tree_dout),
    .din_valid(acc_valid_in),
    .acc_done(acc_ready),
    .dout(acc_data),
    .dout_valid(acc_valid)
);


delay #(
    .DATA_WIDTH(DIN_WIDTH+$clog2(PARALLEL)+3),
    .DELAY_VALUE(OUTPUT_DELAY)
) output_delay_inst (
    .clk(clk),
    .din({acc_data, acc_valid}),
    .dout({dout, dout_valid })
);





endmodule
