`default_nettype none
`include "../vga_controller.v"


/*  
*   Author: Sebastian Jorquera
*
*   xor pattern made by the go board, but is extensible to any
*   other board.
*/



module xor_pattern #(
    parameter H_MAX = 800,
    parameter H_ACTIVE = 640,
    parameter H_FRONT = 18,
    parameter H_SYNC = 92,
    parameter H_BACK = 50,
    parameter V_MAX = 525,
    parameter V_ACTIVE = 480,
    parameter V_FRONT = 10,
    parameter V_SYNC = 2,
    parameter V_BACK = 33
) (

    input wire clk,
    input wire rst_n,

    output wire h_sync,
    output wire v_sync,
    output wire [2:0] red_val,
    output wire [2:0] blue_val,
    output wire [2:0] green_val
);

//localparam MAX_ACTIVE = $MAX($clog2(H_ACTIVE),$clog2(V_ACTIVE));
wire [$clog2(H_ACTIVE)-1:0] x_pos;
wire [$clog2(V_ACTIVE)-1:0] y_pos;
wire valid_pos;

wire [2:0] r_pxl_value;
wire [2:0] g_pxl_value;
wire [2:0] b_pxl_value;


wire [$clog2(H_ACTIVE)-1:0] xor_texture; //x_pos_ext, y_pos_ext;

assign xor_texture = x_pos ^ y_pos;

assign r_pxl_value = xor_texture[$clog2(H_ACTIVE)-2-:3];
assign g_pxl_value = xor_texture[$clog2(H_ACTIVE)-2-:3];
assign b_pxl_value = xor_texture[$clog2(H_ACTIVE)-2-:3];


vga_controller #(
	.H_MAX(H_MAX),
    .H_ACTIVE(H_ACTIVE),
    .H_FRONT(H_FRONT),
    .H_SYNC(H_SYNC),
    .H_BACK(H_BACK),
    .V_MAX(V_MAX),
    .V_ACTIVE(V_ACTIVE),
    .V_FRONT(V_FRONT),
    .V_SYNC(V_SYNC),
    .V_BACK(V_BACK)
) vga_controller_inst (
	.i_Clk(clk),
    .rst_n(rst_n),
    .h_sync(h_sync),
    .v_sync(v_sync),
    .red_val(red_val),
    .blue_val(blue_val),
    .green_val(green_val),
	.x_pos(x_pos),
	.y_pos(y_pos),
	.valid_pos(valid_pos),
	.r_pxl_value(r_pxl_value),
	.g_pxl_value(g_pxl_value),
    .b_pxl_value(b_pxl_value)
);



endmodule
