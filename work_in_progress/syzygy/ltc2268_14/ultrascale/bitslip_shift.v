`default_nettype none

module bitslip_shift #(
    parameter DIN_WIDTH = 8
) (
    input wire clk,
    input wire [DIN_WIDTH-1:0] din,
    input wire enable,
    input wire rst, 
    input wire [$clog2(DIN_WIDTH)-1:0] bitslip_count,
    output wire [DIN_WIDTH-1:0] dout
);

reg [2*DIN_WIDTH-1:0] stages=0;
reg [DIN_WIDTH-1:0] dout_r=0;


integer i;
always@(posedge clk or posedge rst)begin
    if(rst)begin
        stages <= 0;
        dout_r <= 0;
    end
    else if(enable)begin
        /*
        for(i=0; i<DIN_WIDTH; i=i+1)begin
            stages[DIN_WIDTH+i] <= stages[i];
            stages[i]  <= din[DIN_WIDTH-1-i];
        end
        */
        stages <= {din,stages[DIN_WIDTH+:DIN_WIDTH]};
        dout_r <= stages[bitslip_count+:DIN_WIDTH];
    end
end

endmodule

/*
   stage_one <= data_in;
        stage_two <= stage_one;
        case (bitslip_count)
            4'd0: data_out <= stage_two;
            4'd1: data_out <= {stage_one[0],   stage_two[7:1]};
            4'd2: data_out <= {stage_one[1:0], stage_two[7:2]};
            4'd3: data_out <= {stage_one[2:0], stage_two[7:3]};
            4'd4: data_out <= {stage_one[3:0], stage_two[7:4]};
            4'd5: data_out <= {stage_one[4:0], stage_two[7:5]};
            4'd6: data_out <= {stage_one[5:0], stage_two[7:6]};
            4'd7: data_out <= {stage_one[6:0], stage_two[7]};
            default: data_out <= 8'hFF;
         endcase
*/
