`default_nettype none

module unsign_cast #(
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
reg [DOUT_INT-1:0] dout_int=0;
reg [1:0] warning_r=0;
generate 
if(DIN_INT==DOUT_INT)begin
    always@(posedge clk)begin
        dout_int <= din[DIN_WIDTH-1-:DIN_INT];
    end
end
else if(DIN_INT>DOUT_INT)begin
    always@(posedge clk)begin
        if( (|din[DIN_WIDTH-1-:(DIN_INT-DOUT_INT+1)]))begin
            //check overflow, review the condition..
            dout_int <= {(DOUT_INT){1'b1}};
            if(OVERFLOW_WARNING)
                warning_r <=1;
        end
        else begin
            dout_int <= din[DIN_POINT+:DOUT_INT];
            if(OVERFLOW_WARNING)
                warning_r <= 0;
        end
    end
end
else begin
    always@(posedge clk)begin
        dout_int <= {{(DOUT_INT-DIN_INT){1'b0}}, din[DIN_POINT+:DIN_INT]};
    end
end


endgenerate

//fractional part

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

assign warning = warning_r;

endmodule
