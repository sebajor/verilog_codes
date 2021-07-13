`default_nettype none
//`include "includes.v"


module arctan2 #(
    parameter DIN_WIDTH = 16,
    parameter DOUT_WIDTH = 16,
    parameter ROM_FILE = "atan_rom.hex",
    parameter MAX_SHIFT = 7
) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] y,x,
    input wire din_valid,

    output wire sys_ready,
    output wire signed [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);

//register the inputs
reg signed [DIN_WIDTH-1:0] y_r=0, x_r=0;
reg din_valid_r=0;
always@(posedge clk)begin
    y_r <=y;    x_r <=x;
    din_valid_r <= din_valid;
end

//convert the input data to positive
reg [1:0] flag=0;
reg signed [DIN_WIDTH-1:0] y_abs=0, x_abs=0;
reg abs_valid =0, sys_ready_r=0, sys_ready_rr=0;
always@(posedge clk)begin
    sys_ready_r <=sys_ready;
    sys_ready_rr <=sys_ready_r;
    if(sys_ready_rr & din_valid_r)begin
        abs_valid <= 1'b1;
        if(y_r[DIN_WIDTH-1] & ~x_r[DIN_WIDTH-1])begin
            //y<0, x>0 ---> -arctan
            flag <= 1;
            y_abs <= ~y_r+1'b1;
            x_abs <= x_r;
        end 
        else if(~y_r[DIN_WIDTH-1] & x_r[DIN_WIDTH-1])begin
            //y>0, x<0 ---> pi-arctan
            flag <= 2;
            y_abs <= y_r;
            x_abs <= ~x_r+1'b1;
        end
        else if(y_r[DIN_WIDTH-1] & x_r[DIN_WIDTH-1])begin
            //y<0, x<0 ---> -pi+arctan
            flag <=3;
            y_abs <= ~y_r+1'b1;
            x_abs <= ~x_r+1'b1;
        end
        else begin
            flag <=0;
            y_abs <= y_r;
            x_abs <= x_r;
        end
    end
    else begin
        flag <= flag;
        abs_valid <= 0;
    end
end

//if x<y swap them and then the output is pi/2-arctan
reg flag2=0;
reg [DIN_WIDTH-1:0] x_atan=0, y_atan=0;
reg shift_valid=0;
always@(posedge clk)begin
    shift_valid <= abs_valid;
    if(abs_valid)begin
        if(x_abs<y_abs)begin
            flag2 <= 1;
            x_atan <= y_abs;
            y_atan <= x_abs;
        end
        else begin
            flag2 <= 0;
            x_atan <= x_abs;
            y_atan <= y_abs;
        end
    end
    else begin
        flag2 <= flag2;
        x_atan <= x_atan;
        y_atan <= y_atan;
    end
end

//scale the inputs
wire [DIN_WIDTH-1:0] x_scaled, y_scaled;
wire scale_valid;
autoscale #(
    .MAX_SHIFT(MAX_SHIFT),
    .DIN_WIDTH(DIN_WIDTH)
) autoscale_inst (
    .clk(clk),
    .din1(x_atan), 
    .din2(y_atan),
    .din_valid(shift_valid),
    .dout1(x_scaled), 
    .dout2(y_scaled),
    .dout_valid(scale_valid)
);


wire atan_rdy, atan_valid;
wire signed [DOUT_WIDTH-1:0] atan_dout;

arctan #(
    .DIN_WIDTH(DIN_WIDTH),
    .DOUT_WIDTH(DOUT_WIDTH),
    .ROM_FILE(ROM_FILE) 
) arctan_inst ( 
    .clk(clk),
    .y(y_scaled),
    .x(x_scaled),
    .din_valid(scale_valid),
    .sys_ready(atan_rdy),
    .dout(atan_dout),
    .dout_valid(atan_valid)
);

//add the correspondant values
reg signed [DOUT_WIDTH:0] dout_r=0;
reg dout_valid_r=0;
wire signed [DIN_WIDTH-1:0] pi_half = {2'b01, {(DOUT_WIDTH-2){1'b0}}};
wire signed [DIN_WIDTH-1:0] neg_pi_half = ~pi_half+1'b1;
wire signed [DIN_WIDTH-1:0] pi = {1'b0, {(DOUT_WIDTH-1){1'b1}}};
wire signed [DIN_WIDTH-1:0] neg_pi = {1'b1, {(DOUT_WIDTH-1){1'b0}}};
always@(posedge clk)begin
    dout_valid_r <= atan_valid;
    if(atan_valid)begin
        if(flag==2'd0)begin
            if(flag2)
                dout_r <= $signed(pi_half)-$signed(atan_dout);
            else
                dout_r <= atan_dout; 
        end
        else if(flag==2'd1)begin
            if(flag2)
                dout_r <= $signed(atan_dout)-$signed(pi_half); 
            else
                dout_r <= ~atan_dout+1'b1;
        end
        else if(flag==2'd2)begin
            if(flag2)
                dout_r <= $signed(pi_half)+$signed(atan_dout);
            else
                dout_r <= $signed(pi)-$signed(atan_dout);
        end
        else begin
            if(flag2)
                dout_r <= $signed(~atan_dout+1'b1)-$signed(pi_half);
            else
                dout_r <= $signed(atan_dout)-$signed(pi);
        end
    end
end



assign dout = dout_r;
assign dout_valid = dout_valid_r;


//timing of the ready signal
reg shift_valid_r=0;
always@(posedge clk)
    shift_valid_r<= shift_valid;

reg ready=1;
wire busy = abs_valid | shift_valid | scale_valid |din_valid_r |shift_valid_r;
always@(posedge clk)begin
    if(ready & din_valid)
        ready <=1'b0;
    else if(atan_valid)
        ready <= 1'b1;
    else
        ready <= ready;
end

assign sys_ready = ready & atan_rdy;


endmodule
