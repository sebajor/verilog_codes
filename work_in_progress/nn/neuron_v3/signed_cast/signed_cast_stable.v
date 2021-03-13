`default_nettype none 

//checking this would be a pain... we have to check multiple 
//parameters...ufffff


module signed_cast #(
    parameter PARALLEL = 4,
    parameter DIN_WIDTH = 8,
    parameter DIN_INT = 4,
    parameter DOUT_WIDTH = 12,
    parameter DOUT_INT = 5
) (
    input wire clk,
    input wire [DIN_WIDTH*PARALLEL-1:0] din,
    input wire din_valid,
    output wire [DOUT_WIDTH*PARALLEL-1:0] dout,
    output wire dout_valid
);

localparam DIN_POINT = DIN_WIDTH-DIN_INT;
localparam DOUT_POINT = DOUT_WIDTH-DOUT_INT;

//if DOUT_INT < DIN_INT we keep the lower bits ie
//[DIN_POINT+:DOUT_INT], if DOUT_INT>DIN_INT you dont lose info
//but we have to extend the sign

//if DOUT_POINT<DIN_INT we keep the higher fractional bits ie
//[DIN_POINT-:DOUT_POINT], if DIN_POINT<DOUT_POINT you dont lose
//info and fill the lower bits with zeros

//integer part

reg [DOUT_INT*PARALLEL-1:0] dout_int=0;

generate 
integer i;
if(DOUT_INT>DIN_INT)begin
    always@(posedge clk)begin
        for(i=0; i<PARALLEL; i=i+1)begin
            dout_int[DOUT_INT*i+:DOUT_INT] <= {din[DIN_WIDTH*(i+1)-1] ,din[DIN_WIDTH*i+DIN_POINT+:DOUT_INT-1]};
        end
    end
end
else begin
    localparam INT_FILL = DIN_INT-DOUT_INT;
    always@(posedge clk)begin
        for(i=0; i<PARALLEL; i=i+1)begin
            dout_int[DOUT_INT*i+:DOUT_INT] <={{(INT_FILL){din[DIN_WIDTH*(i+1)-1]}}, din[DIN_WIDTH*i+DIN_POINT+:DOUT_INT]};
        end
    end
end
endgenerate


//fractional part
reg [DOUT_POINT*PARALLEL-1:0] dout_frac=0;
generate 
integer j;
if(DOUT_POINT<DIN_POINT)begin
    always@(posedge clk)begin
        for(j=0; j<PARALLEL;j=j+1)begin
            dout_frac[DOUT_POINT*j+:DOUT_POINT] <= din[DIN_WIDTH*j+DIN_POINT-:DOUT_POINT];
        end
    end
end
else begin
    localparam FRAC_FILL = DOUT_POINT-DIN_POINT;
    always@(posedge clk)begin
        for(j=0; j<PARALLEL; j=j+1)begin
            dout_frac[DOUT_POINT*j+:DOUT_POINT] <= {din[DIN_WIDTH*j+DIN_POINT-:DOUT_POINT], {(FRAC_FILL){1'b0}}};
        end
    end
end
endgenerate

//order the output with the fractional and integer part together
genvar k;
for(k=0;k<PARALLEL;k=k+1)begin
    assign dout[DOUT_WIDTH*k+:DOUT_WIDTH] = {dout_int[DOUT_INT*k+DOUT_INT], dout_frac[DOUT_POINT*k+:DOUT_POINT]};
end

//valid delay
reg valid_out=0;
assign dout_valid = valid_out;

always@(posedge clk)begin
    valid_out <= din_valid;
end

endmodule
