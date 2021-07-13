`default_nettype none
`include "includes.v"

/*
    you need to create the sqrt.hex and the arctan.hex with it correspondant
    parameters
*/


module v_uesprit_full #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    //correlation matrix parameters
    parameter VECTOR_LEN = 64,
    parameter CORR_WIDTH = 20,
    parameter CORR_POINT = 16,
    parameter CORR_DOUT_WIDTH = 32,
    //linear algebra parameters
    parameter LA_IN_WIDTH = 16,
    parameter LA_IN_POINT = 15,
    parameter SQRT_IN_WIDTH = 10,
    parameter SQRT_IN_POINT = 7,
    parameter DOUT_WIDTH = 16,
    parameter DOUT_POINT = 13
) (
    input wire clk,
    input wire rst,
    
    input wire signed [DIN_WIDTH-1:0] din1_re, din1_im,
    input wire signed [DIN_WIDTH-1:0] din2_re, din2_im,
    input wire din_valid,
    input wire new_acc,
    
    //for debugging, if timming fails check this singals!
    input wire [4:0] shift, //shift the corr data by this amount
    output wire signed [LA_IN_WIDTH-1:0] r11, r22, r12_re, r12_im,
    output wire corr_valid,
    
    //linear algebra outputs
    output wire signed [DOUT_WIDTH-1:0] lamb1, lamb2,
    output wire signed [DOUT_WIDTH-1:0] eigen1_y, eigen2_y, eigen_x,
    output wire la_valid,

    //arctan outputs
    output wire signed [DOUT_WIDTH-1:0] phase1, phase2,
    output wire phase_valid

);

v_uesprit_la #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .VECTOR_LEN(VECTOR_LEN),
    .CORR_WIDTH(CORR_WIDTH), 
    .CORR_POINT(CORR_POINT),
    .CORR_DOUT_WIDTH(CORR_DOUT_WIDTH), 
    .LA_IN_WIDTH(LA_IN_WIDTH), 
    .LA_IN_POINT(LA_IN_POINT),
    .SQRT_IN_WIDTH(SQRT_IN_WIDTH), 
    .SQRT_IN_POINT(SQRT_IN_POINT),
    .DOUT_WIDTH(DOUT_WIDTH),
    .DOUT_POINT(DOUT_POINT)
) v_uesprit_la_inst (
    .clk(clk),
    .din1_re(din1_re),
    .din1_im(din1_im),
    .din2_re(din2_re),
    .din2_im(din2_im),
    .din_valid(din_valid),
    .new_acc(new_acc),
    .shift(shift),
    .r11(r11),
    .r22(r22),
    .r12_re(r12_re),
    .r12_im(r12_im),
    .corr_valid(corr_valid),
    .lamb1(lamb1),
    .lamb2(lamb2),
    .eigen1_y(eigen1_y),
    .eigen2_y(eigen2_y),
    .eigen_x(eigen_x),
    .dout_valid(la_valid)
);


reg en_save =0, la_valid_r=0;
always@(posedge clk)begin
    la_valid_r <= la_valid;
    //detect rising edge
    if(rst)
        en_save <=0;
    else if(~la_valid_r & la_valid)
        en_save <=1;
    else
        en_save <= en_save;
end

//delay the la output to match en_save
reg [DOUT_WIDTH-1:0] eig1=0, eig2=0, eig_frac=0,l1=0,l2=0;
always@(posedge clk)begin
    eig1 <= eigen1_y;   eig2<= eigen2_y;    eig_frac <= eigen_x;
    l1<=lamb1;  l2<=lamb2;
end

//TODO: I should review how big is one eigenvalue related to the other to 
//"detect" a signal and just save them, in that case we also need to save the freq
//also in that case wouldnt be necesary to save all the signals..
//we only need the eig1,eig_frac and the channel number.

wire fifo_full, fifo_empty;
wire [DOUT_WIDTH-1:0] e1,e2,e_frac, lam1, lam2;

wire read_valid;
reg read_req=0, read_req_r=0;

fifo_sync #(
    .DIN_WIDTH(5*DOUT_WIDTH),
    .FIFO_DEPTH(VECTOR_LEN)
) fifo_sync_inst (
    .clk(clk),
    .rst(rst),
    .wdata({eig1,eig2,eig_frac,l1,l2}),
    .w_valid(en_save & la_valid_r),
    .empty(fifo_empty),
    .full(fifo_full),
    .rdata({e1,e2,e_frac,lam1,lam2}),
    .r_valid(read_valid),
    .read_req(read_req)
);
reg [$clog2(VECTOR_LEN)-1:0] debug=0;
always@(posedge clk)begin
    if(read_valid)
        debug <= debug+1;
end


//cordic atan2
always@(posedge clk)begin
    read_req_r <= read_req;
    if(~fifo_empty & atan_read_req & (~read_req_r & ~read_req) )
        read_req <= 1;
    else
        read_req <=0;
end



wire atan_read_req;
arctan2 #(
    .DIN_WIDTH(DOUT_WIDTH),
    .DOUT_WIDTH(DOUT_WIDTH),
    .ROM_FILE("atan_rom.hex"),
    .MAX_SHIFT(7)
) arctan2_inst (
    .clk(clk),
    .y(e1),
    .x(e_frac),
    .din_valid(read_valid),
    .sys_ready(atan_read_req),
    .dout(phase1),
    .dout_valid(phase_valid)
);








endmodule
