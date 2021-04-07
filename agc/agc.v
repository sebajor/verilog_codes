`default_nettype none
`include "moving_average_unsign.v"
`include "dsp48_mult.v"

/*
din ------------------------------------------------> x --> out
|                                                     |
--->power-->mov avg---> ref comparison --> adjust coef-

Also like we dont want to update the coeficcient any cycle (we could),
the parameter REFRESH_CYCLES  
*/


module agc #(
    parameter DIN_WIDTH = 8,    //its ufix8_7
    parameter DELAY_LINE = 32,
    parameter REFRESH_CYCLES = 1024,
    parameter GAIN_WIDTH = 12,   //its ufix12_10
    parameter [GAIN_WIDTH-1:0] GAIN_LOW_LIM = 12'd12    //the gain couldnt be less than this
) (
    input wire clk,
    input wire rst,

    input wire signed [DIN_WIDTH-1:0] din,
    input wire din_valid,
    
    input wire [2*DIN_WIDTH-1:0] ref_pow,    //ufix16_14    reference power
    input wire [2*DIN_WIDTH-1:0] error_coef, //ufix16_14    coef to adjust the error
                                             //before adding it to the gain

    output wire [DIN_WIDTH-1:0] dout,
    output wire dout_valid
);

localparam GAIN_POINT = GAIN_WIDTH-2;
localparam DIN_POINT = DIN_WIDTH-1;

wire [2*DIN_WIDTH-1:0] din_pow;
wire pow_valid;


//TODO: use a generate to have the option to not use dsp48
dsp48_mult #(
    .DIN1_WIDTH(DIN_WIDTH),
    .DIN2_WIDTH(DIN_WIDTH),
    .DOUT_WIDTH(2*DIN_WIDTH)
) pow_mult (
    .clk(clk),
    .rst(1'b0),
    .din1(din),
    .din2(din),
    .din_valid(din_valid),
    .dout(din_pow),
    .dout_valid(pow_valid)
);


wire [2*DIN_WIDTH-1:0] pow_avg;
wire pow_avg_valid;

moving_average_unsign #(
    .DIN_WIDTH(2*DIN_WIDTH),
    .DIN_POINT(2*DIN_POINT),
    .WINDOW_LEN(DELAY_LINE),
    .DOUT_WIDTH(2*DIN_WIDTH),
    .APPROX("nearest")   //truncate, nearest
) mov_avg(
    .clk(clk),
    .rst(1'b0),
    .din(din_pow),
    .din_valid(pow_valid),
    .dout(pow_avg),
    .dout_valid(pow_avg_valid)
);


reg signed [2*DIN_WIDTH-1:0] ref_diff =0;
reg diff_valid=0;
always@(posedge clk)begin
    diff_valid <= pow_avg_valid;
    if(pow_avg_valid)
        ref_diff <= ref_pow-pow_avg;
    else 
        ref_diff <= ref_diff;
end

//ref_diff<0 --->pow_avg is bigger than ref need to reduce the gain
//ref_diff>0 --->pow_avg is smaller than ref, need to increase gain
wire [4*DIN_WIDTH-1:0] error_adj;
wire adj_valid;


//idem TODO: hw selection
dsp48_mult #(
    .DIN1_WIDTH(2*DIN_WIDTH),
    .DIN2_WIDTH(2*DIN_WIDTH),
    .DOUT_WIDTH(4*DIN_WIDTH)
) diff_adj_mult (
    .clk(clk),
    .rst(1'b0),
    .din1(ref_diff),
    .din2(error_coef),
    .din_valid(diff_valid),
    .dout(error_adj),
    .dout_valid(adj_valid)
);





reg signed [GAIN_WIDTH-1:0] gain_update = {2'b01, {(GAIN_WIDTH-2){1'b0}}}; //fix GAIN_WIDTH, GW-2
reg [$clog2(REFRESH_CYCLES)-1:0] counter=0;
reg gain_update_valid=0;
always@(posedge clk)begin
    if(rst) begin
        gain_update<= {2'b01, {(GAIN_WIDTH-2){1'b0}}};
        counter <= 0;
        gain_update_valid <=0;
    end
    else if((&counter) && (adj_valid))begin
        counter <= counter +1;
        gain_update <= $signed(gain_update)+$signed(error_adj);
        gain_update_valid <= 1;
    end
    else if(gain_update_refused)
        gain_update <= gain;
    else begin
        gain <= gain;
        counter <= counter+1;
        gain_update_valid <=0;
    end
end


reg signed [GAIN_WIDTH-1:0] gain = {2'b01, {(GAIN_WIDTH-2){1'b0}}}; 
reg gain_update_refused =0;
always@(posedge clk)begin
    if(rst)begin
        gain <= {2'b01, {(GAIN_WIDTH-2){1'b0}}};
        gain_update_refused <= 0;
    end
    else if(gain_update_valid)begin
        if(gain_update<GAIN_LOW_LIM)begin
            gain_update_refused <=1;
            gain <= gain;
        end
        else begin
            gain <= gain_update;
            gain_update_refused <=0;
        end
    end
    else begin
        gain <= gain;
        gain_update_refused <= 0;
    end
end

//ponderate the input value
reg signed [GAIN_WIDTH+DIN_WIDTH-1:0] dout_r=0;
reg signed [DIN_WIDTH-1:0] din_dly=0;
always@(posedge clk)begin
    din_dly <= din;
    dout_r <= $signed(gain)*$signed(din_dly);
end

//match the dout size
assign dout = dout_r[GAIN_POINT+DIN_POINT+1-:DIN_WIDTH]; //check

endmodule
