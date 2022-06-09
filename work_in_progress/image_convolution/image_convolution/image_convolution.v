`default_nettype none

/*
*   Author: Sebastian Jorquera
*   this module makes a convolution using a parametrizable kernel
*   it doesnt handle the boundary problem, it just calculate the conv in
*   the areas that are fully contained by the kernel.
*/
module image_convolution #(
    parameter DIN_WIDTH = 8,
    parameter DIN_POINT = 7,
    parameter KERNEL_SIZE = 3,
    parameter WEIGHT_WIDTH = 8,
    parameter WEIGHT_POINT = 7,
    parameter WEIGHT_FILE = "weight/kern.mem",
    parameter DOUT_WIDTH = 8,
    parameter DOUT_POINT = 7
) (
    input wire clk,
    input wire [KERNEL_SIZE*KERNEL_SIZE*DIN_WIDTH-1:0] din,
    input wire din_valid,
    output wire [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);

reg [WEIGHT_WIDTH-1:0] kernel [KERNEL_SIZE*KERNEL_SIZE-1:0];
initial begin
    $readmemb(WEIGHT_FILE, kernel);
end

reg [KERNEL_SIZE*KERNEL_SIZE*DIN_WIDTH-1:0] din_r=0;
reg din_valid_r=0;
always@(posedge clk)begin
    din_r <= din;
    din_valid_r <= din_valid;
end


genvar i;
localparam MULT_WIDHT = WEIGHT_WIDTH+DIN_WIDTH+1;
localparam MULT_POINT = WEIGHT_POINT+DIN_POINT;

wire [MULT_WIDHT*KERNEL_SIZE*KERNEL_SIZE-1:0] mult_out;
wire [KERNEL_SIZE*KERNEL_SIZE-1:0] mult_valid;
generate
for (i=0; i<KERNEL_SIZE*KERNEL_SIZE; i=i+1)begin:loop
    dsp48_mult #(
        .DIN1_WIDTH(DIN_WIDTH+1),
        .DIN2_WIDTH(WEIGHT_WIDTH),
        .DOUT_WIDTH(MULT_WIDHT)
    ) mult_inst (
        .clk(clk),
        .rst(1'b0),
        .din1({1'b0, din_r[DIN_WIDTH*i+:DIN_WIDTH]}),
        .din2(kernel[i]),
        .din_valid(din_valid_r),
        .dout(mult_out[i*MULT_WIDHT+:MULT_WIDHT]),
        .dout_valid(mult_valid[i])
    );
end
endgenerate

localparam ADD_WIDTH = MULT_WIDHT+$clog2(KERNEL_SIZE*KERNEL_SIZE);
wire signed [ADD_WIDTH-1:0] add_out;
wire add_valid;

adder_tree #(
    .DATA_WIDTH(MULT_WIDHT),
    .PARALLEL(KERNEL_SIZE*KERNEL_SIZE)
) adder_tree_inst (
    .clk(clk),
    .din(mult_out),
    .din_valid(mult_valid[0]),
    .dout(add_out),
    .dout_valid(add_valid)
);

wire [ADD_WIDTH-1:0] add_out_r = add_out;
//there is a bug..the sync of the add_out and the add_valid dont match
//reg [ADD_WIDTH-1:0] add_out_r=0;
//always@(posedge clk)
//    add_out_r <= add_out;



signed_cast #(
    .DIN_WIDTH(ADD_WIDTH),
    .DIN_POINT(MULT_POINT),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT)
) cast_inst (
    .clk(clk), 
    .din(add_out_r),
    .din_valid(add_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);



endmodule
