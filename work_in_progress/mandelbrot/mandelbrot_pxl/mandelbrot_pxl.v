`default_nettype none

module mandelbrot_pxl #(
    parameter DIN_WIDTH = 32,
    parameter DIN_POINT = 12
)(
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] x_init, y_init,
    input wire signed [DIN_WIDTH-1:0] c_re, c_im,
    input wire [31:0] iters,
    input wire din_valid,
    
    output wire busy,
    output wire [31:0] dout,
    output wire dout_valid
);

//states
localparam IDLE = 1'b0,
           BUSY=1'b1;

reg state=IDLE;

//output signals
reg [31:0] counter=0;
reg dout_valid_r=0;

assign dout = counter;
assign dout_valid = dout_valid_r;
assign busy = state;

//operation signals
reg allow_op=0;
wire signed [DIN_WIDTH-1:0] op_re, op_im;
wire op_valid;
wire [1:0] op_ovf_re, op_ovf_im;
wire op_ovf;
assign op_ovf = (|op_ovf_re) | (|op_ovf_im);

reg signed [31:0] temp_re=0, temp_im;
always@(posedge clk)begin
    if(state==IDLE)begin
        counter <=0;
        dout_valid_r <=0;
        if(din_valid)begin
            temp_re<=x_init;
            temp_im<=y_init;
            allow_op <=1;
            state <= BUSY;
        end
        else begin
            temp_re<=0;
            temp_im<=0;
            allow_op<=0;
            state <= IDLE;
        end
    end
    else begin
        if(op_valid)begin
            temp_re <= op_re;
            temp_im <= op_im;
            counter <= counter+1;
            if(op_ovf | (counter==(iters-1)))begin
                dout_valid_r <=1;
                state <= IDLE;
                allow_op <=0;
            end
            else begin
                allow_op <=1;
                dout_valid_r <=0;
                state <= BUSY; 
            end
        end
        else begin
            allow_op <=0;
            dout_valid_r<=0;
            state <= BUSY;
        end
    end
end

wire signed [2*DIN_WIDTH:0] mult_re, mult_im; 
wire mult_valid;

complex_mult #(
    .DIN1_WIDTH(DIN_WIDTH),
    .DIN2_WIDTH(DIN_WIDTH)
) complex_mult_inst(
    .clk(clk),
    .din1_re(temp_re),
    .din1_im(temp_im),
    .din2_re(temp_re),
    .din2_im(temp_im),
    .din_valid(allow_op),
    .dout_re(mult_re),
    .dout_im(mult_im),
    .dout_valid(mult_valid)
);

localparam MULT_POINT = 2*DIN_POINT;

wire signed [2*DIN_WIDTH-DIN_POINT:0] c_re_ext = $signed(c_re);
wire signed [2*DIN_WIDTH-DIN_POINT:0] c_im_ext = $signed(c_im);


reg signed [2*DIN_WIDTH-DIN_POINT:0] out_re=0, out_im=0;
reg out_valid=0;
always@(posedge clk)begin
    if(mult_valid)begin
        out_re <= $signed(mult_re[2*DIN_WIDTH:DIN_POINT])+$signed(c_re_ext);
        out_im <= $signed(mult_im[2*DIN_WIDTH:DIN_POINT])+$signed(c_im_ext);
        out_valid <=1;
    end
    else
        out_valid <=0;
end

signed_cast #(
    .DIN_WIDTH(2*DIN_WIDTH-DIN_POINT+1),
    .DIN_POINT(DIN_POINT),
    .DOUT_WIDTH(DIN_WIDTH),
    .DOUT_POINT(DIN_POINT),
    .OVERFLOW_WARNING(1)
) cast_re (
    .clk(clk), 
    .din(out_re),
    .din_valid(out_valid),
    .dout(op_re),
    .warning(op_ovf_re),
    .dout_valid(op_valid)
);

signed_cast #(
    .DIN_WIDTH(2*DIN_WIDTH-DIN_POINT+1),
    .DIN_POINT(DIN_POINT),
    .DOUT_WIDTH(DIN_WIDTH),
    .DOUT_POINT(DIN_POINT),
    .OVERFLOW_WARNING(1)
) cast_im (
    .clk(clk), 
    .din(out_im),
    .din_valid(out_valid),
    .dout(op_im),
    .warning(op_ovf_im),
    .dout_valid()
);


endmodule
