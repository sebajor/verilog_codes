`default_nettype none


/*
*   Author: Sebastian Jorquera
*   
*   This module convert signed data types, we keep the less significant
*   bits in the integer part (or saturate if the integer is bigger than
*   the biggest value of the output integer).
*
*   Also takes the most significant bits of the fractional parts (fill with zeros
*   if the fractional output is larger than the fractional input)
*
*   As we only saturate in the integer part could be moments where the
*   saturation value is different,  specifically for the negative values,
*   in theory you could represent -2**(dout_int-1) but when adding the frac part
*   it gets diminish..but at least your saturation goes up to
*    -(2**(dout_int-1)-1+frac) and when you dont have fractional part the
*   saturation goes to -2**(dout_int-1)
*
*   I didnt fix it because the if-else conditions are horrible enough to also
*   make them in just one generate statment aagg
*   
*   If OVERFLOW_WARNING is 1 the warning output will be 1 if there is an overflow
*   2 if there is an underflow and 0 if everything is ok. 
*
*/

module signed_cast #(
    parameter DIN_WIDTH = 8,
    parameter DIN_POINT = 4,
    parameter DOUT_WIDTH = 16,
    parameter DOUT_POINT = 11,
    parameter OVERFLOW_WARNING = 0
) (
    input wire clk, 
    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,
    output wire [DOUT_WIDTH-1:0] dout,
    output wire dout_valid,
    output wire [1:0] warning
);
localparam DIN_INT = DIN_WIDTH-DIN_POINT;
localparam DOUT_INT = DOUT_WIDTH-DOUT_POINT;

initial begin
    $display("Conveting %d,%d to %d,%d ", DIN_WIDTH, DIN_POINT, DOUT_WIDTH, DOUT_POINT);
    //$display("Overflow warning %d", OVERFLOW_WARNING);
end

//integer part
/* if DOUT_INT < DIN_INT we keep the lower bits; [DIN_POINT+:DOUT_INT]
In the case when the data is bigger than DOUT_INT we saturate
if DOUT_INT > DIN_INT you dont lose info but you have to extend the sign
*/

reg [DOUT_INT-1:0] dout_int=0;
reg [2:0] debug=0;
generate 
if(DIN_INT==DOUT_INT)begin
    always@(posedge clk)begin   //check
        dout_int <= din[DIN_WIDTH-1-:DIN_INT];
    end
end
else if(DIN_INT>DOUT_INT)begin
    always@(posedge clk) begin
        //check overflow, check msb to check the sign and look for any one above DOUT_INT
        if(~din[DIN_WIDTH-1] & (|din[DIN_WIDTH-1-:DIN_INT-DOUT_INT+1]))begin
            dout_int <= {1'b0, {(DOUT_INT-1){1'b1}}}; 
        end
        //check underflow, check the msb and look for a zero above DOUT_INT 
        else if(din[DIN_WIDTH-1] & ~(&din[DIN_WIDTH-1-:DIN_INT-DOUT_INT+1]))begin
            dout_int <= {1'b1, {(DOUT_INT-1){1'b0}}}; 
        end
        //else take the sign and the data 
        else begin
            if(DOUT_INT==1)
                dout_int <= {din[DIN_WIDTH-1]};
            else
                dout_int <= {din[DIN_WIDTH-1], din[DIN_POINT+:(DOUT_INT-1)]};
        end
    end
end
//extend the sign 
else begin
    always@(posedge clk)begin
        dout_int <= {{(DOUT_INT-DIN_INT){din[DIN_WIDTH-1]}},din[DIN_POINT+:DIN_INT]};
    end
end
endgenerate


//fractional part
/*
if DOUT_POINT<DIN_POINT we keep the higher fractional bits ie [DIN_POINT-:DOUT_POINT], 
if DIN_POINT<DOUT_POINT you dont lose info and fill the lower bits with zeros
*/

reg [DOUT_POINT-1:0] dout_frac=0;
generate
    if(DOUT_POINT<=DIN_POINT)begin
        //discard the lsb that we cant represent by dout
        always@(posedge clk)begin
            dout_frac <= din[DIN_POINT-1-:DOUT_POINT];
        end
    end
    else begin
        //fill the spaces with zeros 
        localparam FRAC_FILL = DOUT_POINT-DIN_POINT;
        always@(posedge clk)begin
            dout_frac <= {din[DIN_POINT-1-:DIN_POINT], {(FRAC_FILL){1'b0}}};
        end
    end
endgenerate

assign dout = {dout_int, dout_frac};

reg valid_out=0;
assign dout_valid = valid_out;
always@(posedge clk)
    valid_out <= din_valid;

reg [1:0] warning_r=0;
assign warning = warning_r;
generate
if(OVERFLOW_WARNING)begin
    always@(posedge clk)begin
        //check overflow, check msb to check the sign and look for any one above DOUT_INT
        if(~din[DIN_WIDTH-1] & (|din[DIN_WIDTH-1-:DIN_INT-DOUT_INT+1]))begin
            warning_r <= 1;
        end
        //check underflow, check the msb and look for a zero above DOUT_INT 
        else if(din[DIN_WIDTH-1] & ~(&din[DIN_WIDTH-1-:DIN_INT-DOUT_INT+1]))begin
            warning_r <= 2;
        end
        else
            warning_r <= 0;
    end
end


endgenerate

endmodule
