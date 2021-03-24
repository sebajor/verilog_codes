`default_nettype none
`include "avg_pow.v"
`include "signed_cast.v"

/*
din ------------------------------------------------> x --> out
|                                                     |
--->power-->mov avg---> ref comparison --> adjust coef-

Also like we dont want to update the coeficcient any cycle (we could),
the parameter REFRESH_CYCLES  
*/



module agc #(
    parameter DIN_WIDTH =8,     //ufix8_7
    parameter DELAY_LINE = 32,
    parameter REFRESH_CYCLES = 1024,
    parameter ERROR_POINT = 14,
    parameter GAIN_WIDTH = 12,
    parameter GAIN_POINT = 10,
    parameter GAIN_HIGH_LIM = 32,
    parameter GAIN_LOW_LIM = 4 
) (
    input wire clk,
    input wire rst,

    input wire signed [DIN_WIDTH-1:0] din,
    input wire din_valid,

    input wire [2*DIN_WIDTH-1:0] ref_pow,   //ufix16_14
    input wire [2*DIN_WIDTH-1:0] error_coef, //ufix(2*din_width)_error_point

    output wire [GAIN_WIDTH-1:0] gain,
    output wire gain_valid
);


//input power calculation
wire [2*DIN_WIDTH-1:0] pow_avg_dout;
wire pow_avg_valid;

avg_pow #(
    .DIN_WIDTH(DIN_WIDTH),
    .DELAY_LINE(DELAY_LINE) 
) avg_pow_inst (
    .clk(clk),
    .rst(rst),
    .din(din),
    .din_valid(din_valid),
    .dout(pow_avg_dout),
    .dout_valid(pow_avg_valid)
);


//calculate the reference difference
reg signed [2*DIN_WIDTH-1:0] ref_diff =0;
reg diff_valid=0;
always@(posedge clk)begin
    diff_valid <= pow_avg_valid;
    if(pow_avg_valid)
        ref_diff <= ref_pow-pow_avg_dout;
    else
        ref_diff <= ref_diff;
end

//ref_diff<0 --->pow_avg is bigger than ref need to reduce the gain
//ref_diff>0 --->pow_avg is smaller than ref, need to increase gain
localparam POW_POINT = 2*DIN_WIDTH-2;


wire signed [4*DIN_WIDTH-1:0] coef_out;
wire coef_valid;
dsp48_mult #(
    .DIN1_WIDTH(2*DIN_WIDTH),
    .DIN2_WIDTH(2*DIN_WIDTH),
    .DOUT_WIDTH(4*DIN_WIDTH)
) coef_adj_mult (
    .clk(clk),
    .rst(rst),
    .din1(ref_diff),
    .din2(error_coef),
    .din_valid(diff_valid),
    .dout(coef_out),
    .dout_valid(coef_valid)
);

//resize the coef
localparam GAIN_INT = GAIN_WIDTH-GAIN_POINT;
wire signed [GAIN_WIDTH-1:0] gain_error;
wire gain_error_valid;
signed_cast #(
    .PARALLEL(1),
    .DIN_WIDTH(4*DIN_WIDTH),
    .DIN_INT(2),
    .DOUT_WIDTH(GAIN_WIDTH),
    .DOUT_INT(GAIN_INT)
)gain_cast (
    .clk(clk),
    .din(coef_out),
    .din_valid(coef_valid),
    .dout(gain_error),
    .dout_valid(gain_error_valid)
);

//previous update
reg signed [GAIN_WIDTH-1:0] gain_upd=0;
reg gain_upd_valid=0;
reg [$clog2(REFRESH_CYCLES)-1:0] counter=0;

always@(posedge clk)begin
    if(rst)begin
        gain_upd <= {{(GAIN_INT){1'b0}}, {1'b0},{(GAIN_POINT-1){1'b0}}}; // 0.5?
        counter <=0;
        gain_upd_valid <=0;
    end 
    else if((&counter) && gain_error_valid)begin
        counter <=counter+1;
        gain_upd <= $signed(gain_upd)+$signed(gain_error);
        gain_upd_valid<=1;
    end
    else if(gain_upd_refused)begin
        gain_upd_valid <=0;
        gain_upd <= gain_reg;
    end
    else begin
        gain_upd <= gain_upd;
        counter <= counter+1;
        gain_upd_valid <=0;
    end
end

reg signed [GAIN_WIDTH-1:0] gain_reg = {{(GAIN_INT){1'b0}}, {1'b0},{(GAIN_POINT-1){1'b0}}};
reg gain_upd_refused=0, gain_valid_r=0;

always@(posedge clk)begin
    if(rst)begin
        gain_reg = {{(GAIN_INT){1'b0}}, {1'b0},{(GAIN_POINT-1){1'b0}}};
        gain_upd_refused <=0;
        gain_valid_r <=0;
    end
    else if(gain_upd_valid)begin
        gain_valid_r <=1;
        if((gain_upd>GAIN_HIGH_LIM) | (gain_upd<GAIN_LOW_LIM))begin
            gain_reg <= gain_reg;
            gain_upd_refused <=1;
        end
        else begin
            gain_reg <= gain_upd;
            gain_upd_refused<=0;
        end
    end
    else begin
        gain_reg <= gain_reg;
        gain_upd_refused <=0;
    end
end

assign gain = gain_reg;
assign gain_valid = gain_valid_r;



endmodule
