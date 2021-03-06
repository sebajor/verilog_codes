`default_nettype none

/*  Here we use two types of distortions
    the clipping in the high peaks of the sinewave (typical saturation of the amps)
    and crossover distortion which comes from the near zero amplification

*/

module distortion #(
    parameter DIN_WIDTH = 32,
    //parameter LOW_CLIP = -2**20,      //clipping values
    parameter HIGH_CLIP = 2**20,
    parameter CROSS_DISTORTION = 1, //1 or zero, if you want that effect
    parameter CROSS_THRESH = 2**12,  //(-thresh/2, thresh/2) 
    parameter CROSS_AMP = 1         //2**cross_amp

) (
    input wire clk,
    input wire signed [DIN_WIDTH-1:0] din,
    input wire din_tvalid,
    output wire din_tready,
    
    output wire signed [DIN_WIDTH-1:0] dout,
    output wire dout_tvalid,
    input wire dout_tready
);

localparam signed LOW_CLIP = -HIGH_CLIP;
localparam signed LOW_CROSS_THRESH = -CROSS_THRESH;

assign din_tready = 1'b1;

reg signed [DIN_WIDTH-1:0] dat=0;
assign dout = dat;

reg [1:0] test =0;
wire signed [31:0] test_low = LOW_CLIP;
wire signed [31:0] test_high = HIGH_CLIP;


generate 
if(CROSS_DISTORTION)begin
    always@(posedge clk)begin
        if(din_tvalid)begin
            if($signed(din)>$signed(HIGH_CLIP))begin
                dat <= $signed(HIGH_CLIP);
                test <= 1;
            end
            else if($signed(din)<$signed(LOW_CLIP))begin
                dat <= LOW_CLIP;
                test <= 2;
            end
            else if(($signed(din)<$signed(CROSS_THRESH*2)) && ($signed(din)>$signed(CROSS_THRESH)))begin
                dat <= CROSS_THRESH*2;
            end
            else if(($signed(din)<=$signed(CROSS_THRESH)) && ($signed(din)>0))begin
                dat <= $signed(din)<<<CROSS_AMP;
            end
            else if(($signed(din)<0) && ($signed(din)>($signed(LOW_CROSS_THRESH))))begin
                dat <= $signed(din)<<<CROSS_AMP;
            end
            else if(($signed(din)<=LOW_CROSS_THRESH) && ($signed(din)>($signed(LOW_CROSS_THRESH*2))))begin
                dat <= LOW_CROSS_THRESH*2;
            end
            /*
            else if(($signed(din)<$signed(CROSS_THRESH)) && ($signed(din)>($signed(LOW_CROSS_THRESH))))begin
                //dat <= $signed(din)*2;
                dat <= $signed(din)<<<CROSS_AMP;
                test <= 3;
            end
            */
            else begin
                dat <= din;
                test <= 0;
            end
        end
    end
end
else begin
    always@(posedge clk)begin
        if(din_tvalid)begin
            if($signed(din)>$signed(HIGH_CLIP))begin
                dat <= $signed(HIGH_CLIP);
                test<= 1;
            end
            else if($signed(din)<$signed(LOW_CLIP))begin
                dat <= $signed(LOW_CLIP);
                test <=2;
            end
            else begin
                test <=0;
                dat <= din;
            end
        end
    end
end
endgenerate

reg valid_r=0;
assign dout_tvalid = valid_r;

always@(posedge clk)begin
    if(din_tvalid)begin
        valid_r <= 1;
    end
    else if(dout_tready)
        valid_r <= 0;
    else 
        valid_r <= valid_r;
end


endmodule
