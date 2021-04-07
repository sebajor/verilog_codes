`default_nettype none
`include "avg_pow.v"
`include "signed_cast.v"

/*
din ----------------------------------------------------------->x --> out
|                                                               |
--->power-->mov avg---> ref comparison (mov_avg*gain-ref) --> adjust coef

Also like we dont want to update the coeficcient any cycle (we could),
the parameter REFRESH_CYCLES  
I think this is not optimal, the final multiplier should be 
sqrt(gain)*din--> we need to add other parameter!
for the range (0,4) the sqrt is aprox f(x) ~ 0.4x+ 0.5
*/


module agc #(
    parameter DIN_WIDTH = 8,
    parameter DIN_POINT = 7,
    parameter PARALLEL = 8,
    parameter DELAY_LINE = 64,
    parameter AVG_POW_APROX = "nearest",
    parameter UPDATE_CYCLES = 1024,
    parameter COEF_WIDTH = 16,
    parameter COEF_POINT = 8,
    parameter GAIN_WIDTH = 16,
    parameter GAIN_POINT = 8,
    parameter GAIN_HIGH = 2048, //in sd is 8
    parameter GAIN_LOW = 0
) (
    input wire clk,
    input wire rst,

    input wire [DIN_WIDTH*PARALLEL-1:0] din,
    input wire din_valid,
    
    input wire [2*DIN_WIDTH-1:0] ref_pow,
    input wire [COEF_WIDTH-1:0] error_coef,
    
    output wire signed [GAIN_WIDTH-1:0] gain_out,
    output wire gain_out_valid,

    output wire signed [PARALLEL*(DIN_WIDTH+GAIN_WIDTH)-1:0] dout,
    output wire dout_valid
);

wire [2*DIN_WIDTH-1:0] avg_pow_out;
wire avg_pow_out_valid;

avg_pow #(
    .DIN_WIDTH(DIN_WIDTH),
    .PARALLEL(PARALLEL),
    .DELAY_LINE(DELAY_LINE),
    .APROX(AVG_POW_APROX)
) avg_pow_inst (
    .clk(clk),
    .rst(rst),
    .din(din),
    .din_valid(din_valid),
    .dout(avg_pow_out),
    .dout_valid(avg_pow_out_valid)
);
localparam POW_POINT = 2*DIN_POINT;

//ise needs the registers defined previous it use..
reg signed [GAIN_WIDTH-1:0] gain_reg={{(GAIN_INT-1){1'b0}}, {1'b1},{GAIN_POINT{1'b0}}};
reg gain_valid=0;

//calculate gain*avg_pow 
wire [2*DIN_WIDTH+GAIN_WIDTH-1:0] avg_pow_mult;
wire avg_pow_mult_valid;

dsp48_mult #(
    .DIN1_WIDTH(2*DIN_WIDTH),
    .DIN2_WIDTH(GAIN_WIDTH),
    .DOUT_WIDTH(2*DIN_WIDTH+GAIN_WIDTH)
) avg_pow_gain_mult (
    .clk(clk),
    .din1(avg_pow_out),
    .din2(gain_reg),
    .din_valid(avg_pow_out_valid),
    .dout(avg_pow_mult),
    .dout_valid(avg_pow_mult_valid)
);

//resize the output
localparam AVG_MULT_POINT = 2*DIN_POINT+GAIN_POINT;
wire [2*DIN_WIDTH-1:0] avg_pow_mult_red;
assign avg_pow_mult_red = avg_pow_mult[GAIN_POINT+:2*DIN_WIDTH];



//calculate reference difference
reg signed [2*DIN_WIDTH-1:0] ref_diff=0;
reg diff_valid=0;

always@(posedge clk)begin
    diff_valid <= avg_pow_out_valid;
    if(avg_pow_out_valid)
        ref_diff <= ref_pow-avg_pow_mult_red;
    else
        ref_diff <= ref_diff;
end

//ref_diff<0 --->pow_avg is bigger than ref need to reduce the gain
//ref_diff>0 --->pow_avg is smaller than ref, need to increase gain
localparam COEF_OUT_WIDTH = 2*DIN_WIDTH+COEF_WIDTH;
localparam COEF_OUT_POINT = 2*DIN_POINT+COEF_POINT; 
localparam COEF_OUT_INT = COEF_OUT_WIDTH-COEF_OUT_POINT;


wire signed [COEF_OUT_WIDTH-1:0] coef_out;
wire coef_valid;

dsp48_mult #(
    .DIN1_WIDTH(2*DIN_WIDTH),
    .DIN2_WIDTH(COEF_WIDTH),
    .DOUT_WIDTH(2*DIN_WIDTH+COEF_WIDTH)
) coef_adj_mult (
    .clk(clk),
    .din1(ref_diff),
    .din2(error_coef),
    .din_valid(diff_valid),
    .dout(coef_out),
    .dout_valid(coef_valid)
);

localparam GAIN_INT = GAIN_WIDTH-GAIN_POINT;

wire signed [GAIN_WIDTH-1:0] gain_error;
wire gain_err_valid;

signed_cast #(
    .PARALLEL(1),
    .DIN_WIDTH(COEF_OUT_WIDTH),
    .DIN_INT(COEF_OUT_INT),
    .DOUT_WIDTH(GAIN_WIDTH),
    .DOUT_INT(GAIN_INT)
)gain_cast (
    .clk(clk),
    .din(coef_out),
    .din_valid(coef_valid),
    .dout(gain_error),
    .dout_valid(gain_err_valid)
);

//update the gain_value
reg signed [GAIN_WIDTH-1:0] gain_upd=0;
reg gain_upd_valid=0;
reg [$clog2(UPDATE_CYCLES)-1:0] counter=0;

always@(posedge clk)begin
    if(rst)begin
        gain_upd <= 0;
        counter <=0;
        gain_upd_valid <=0;
    end
    else if((&counter) && gain_err_valid)begin
        counter <= counter+1;
        gain_upd <= $signed(gain_upd)+$signed(gain_error);
        gain_upd_valid <=1;
    end
    else begin
        gain_upd <= gain_reg;
        counter <= counter+1;
        gain_upd_valid <=0;
    end
end


always@(posedge clk)begin
    if(rst)begin
        gain_reg <= {{(GAIN_INT-1){1'b0}}, {1'b1},{GAIN_POINT{1'b0}}};
        gain_valid <=0;
    end
    else if(gain_upd_valid)begin
        gain_valid <=1;
        if(($signed(gain_upd)<$signed(GAIN_HIGH)) && ($signed(gain_upd)>$signed(GAIN_LOW)))begin
            gain_reg <= gain_upd;
            gain_valid <=1;
        end
        else begin
            gain_reg <= gain_reg;
            gain_valid <=1;
        end
    end
    else begin
        gain_reg <= gain_reg;
        gain_valid <= 0;
    end
end



//adjust the input using a linear aprox for the sqrt
//
reg [PARALLEL*GAIN_WIDTH-1:0] gain_parallel;
wire [PARALLEL-1:0] adj_valid;
integer i;
wire [GAIN_WIDTH-1:0] linear_off = {{(GAIN_INT){1'b0}},{3'b010},{(GAIN_POINT-3){1'b0}}};    //0.125

always@(posedge clk)begin
    for(i=0; i<PARALLEL; i=i+1)begin
        gain_parallel[GAIN_WIDTH*i+:GAIN_WIDTH] <= (gain_reg>>>1)+linear_off;
    end
end

//assign gain_out = gain_reg;
assign gain_out = gain_parallel[0+:GAIN_WIDTH];
assign gain_out_valid = gain_valid;

parallel_mult #(
    .PARALLEL(PARALLEL),
    .DIN1_WIDTH(DIN_WIDTH),
    .DIN2_WIDTH(GAIN_WIDTH),
    .DOUT_WIDTH(DIN_WIDTH+GAIN_WIDTH)
) adjust_din (
    .clk(clk),
    .din1(din),
    .din2(gain_parallel),
    .din_valid(din_valid),
    .dout(dout),
    .dout_valid(adj_valid)
);

assign dout_valid = adj_valid[0];

endmodule 
