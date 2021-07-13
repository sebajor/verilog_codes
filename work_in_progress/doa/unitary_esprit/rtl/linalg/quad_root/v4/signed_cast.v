`default_nettype none 

//this module converts signed data types, we keep the less 
//significant bits in the integer part (but if there are any upper bit
//that we cant represent in the dout the module saturate to the
//biggest/lower integer value
//in the fractional part we keep the most significant bits and we
//fill with zeros if the lenght of the fractional part of the output
//is bigger.
//As we only saturate in the integer part could be moments where the 
//saturation value is different,  specifically for the negative values,
//in theory you could represent -2**(dout_int-1) but when adding the frac part
//it gets diminish..but at least your saturation goes up to 
// -(2**(dout_int-1)-1+frac) and when you dont have fractional part the
//saturation goes to -2**(dout_int-1)
//I didnt fix it because the if-else conditions are horrible enough to also 
//make them in just one generate statment aagg


module signed_cast #(
    parameter PARALLEL = 4,
    parameter DIN_WIDTH = 8,
    parameter DIN_INT = 4,
    parameter DOUT_WIDTH = 16,
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
//also we saturate the output if the data is bigger
//than the DOUT_INT


//if DOUT_POINT<DIN_POINT we keep the higher fractional bits ie
//[DIN_POINT-:DOUT_POINT], if DIN_POINT<DOUT_POINT you dont lose
//info and fill the lower bits with zeros


//integer part
reg [DOUT_INT*PARALLEL-1:0] dout_int=0;

//maybe would be best just rise a flag when under/overflow and change the
//dout always instead this one..
generate 
integer i;
if(DIN_INT>DOUT_INT)begin
    reg [2*PARALLEL-1:0] debug=0;
    always@(posedge clk)begin
        for(i=0; i<PARALLEL; i=i+1)begin
            //overflow check the msb and see if there is a one in the bits that
            //we cant represent in dout
            if(~din[DIN_WIDTH*(i+1)-1] & (|din[DIN_WIDTH*(i+1)-1-:DIN_INT-DOUT_INT+1]))begin
                dout_int[DOUT_INT*i+:DOUT_INT] <= {1'b0, {(DOUT_INT-1){1'b1}}};
                debug[2*i+:2] <= 2'b1;
            end
            //underflow check the msb and see if there is a zero in the bits
            //that we cant represent in dout
            else if(din[DIN_WIDTH*(i+1)-1] & ~(&din[DIN_WIDTH*(i+1)-1-:DIN_INT-DOUT_INT+1]))begin
                dout_int[DOUT_INT*i+:DOUT_INT] <= {1'b1, {(DOUT_INT-1){1'b0}}};
                debug[2*i+:2] <= 2'b10;
            end
            //if not, take the sign and the data
            else begin
                dout_int[DOUT_INT*i+:DOUT_INT] <= {din[DIN_WIDTH*(i+1)-1], din[DIN_WIDTH*i+DIN_POINT+:DOUT_INT-1]};
                debug[2*i+:2] <= 2'b0;
            end
        end
    end
end
else begin
    //here we have enough space to allocate the din data so we have to
    //expand the sign the necesary number of bits
    always@(posedge clk)begin
        for(i=0; i<PARALLEL; i=i+1)begin
            dout_int[DOUT_INT*i+:DOUT_INT] <={{(DOUT_INT-DIN_INT){din[DIN_WIDTH*(i+1)-1]}}, din[DIN_WIDTH*i+DIN_POINT+:DIN_INT]};
        end
    end
end
endgenerate


//fractional part
reg [DOUT_POINT*PARALLEL-1:0] dout_frac=0;
generate 
integer j;
if(DOUT_POINT<DIN_POINT)begin
    //here we discard the lsb that we cant represent in the dout
    always@(posedge clk)begin
        for(j=0; j<PARALLEL;j=j+1)begin
            dout_frac[DOUT_POINT*j+:DOUT_POINT] <= din[DIN_WIDTH*j+DIN_POINT-1-:DOUT_POINT];
        end
    end
end
else begin
    //here we have enough room for the bits in the dout part, so
    //we fullfill with zeros (there is any problem in the negative values?)
    localparam FRAC_FILL = DOUT_POINT-DIN_POINT;
    always@(posedge clk)begin
        for(j=0; j<PARALLEL; j=j+1)begin
            dout_frac[DOUT_POINT*j+:DOUT_POINT] <= {din[DIN_WIDTH*j+DIN_POINT-1-:DIN_POINT], {(FRAC_FILL){1'b0}}};
        end
    end
end
endgenerate

//order the output with the fractional and integer part together
genvar k;
for(k=0;k<PARALLEL;k=k+1)begin
    assign dout[DOUT_WIDTH*k+:DOUT_WIDTH] = {dout_int[DOUT_INT*k+:DOUT_INT], dout_frac[DOUT_POINT*k+:DOUT_POINT]};
end

//valid delay
reg valid_out=0;
assign dout_valid = valid_out;

always@(posedge clk)begin
    valid_out <= din_valid;
end

endmodule
