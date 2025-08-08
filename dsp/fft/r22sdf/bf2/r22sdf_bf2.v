`default_nettype none

/*
*   Author: sebastian jorquera
*/

module r22sdf_bf2 #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 15,
    parameter BUFFER_SIZE = 16,
    parameter DELAY_TYPE = "RAM"    //ram or delay; ram has a 2 cycle read delay too
) (
    input wire clk, 
    input wire signed [DIN_WIDTH-1:0] din_re, din_im,
    input wire din_valid,
    input wire rst,

    output wire signed [DIN_WIDTH:0] dout_re, dout_im,
    output wire dout_valid
);

reg [1:0] state = 0;
reg [$clog2(BUFFER_SIZE)+1:0] counter =0;
reg dout_valid_r =0, dout_valid_rr=0;
reg [DIN_WIDTH:0] dout_re_r=0,  dout_im_r=0;

assign dout_valid = dout_valid_rr;
assign dout_re = dout_re_r;
assign dout_im = dout_im_r;


always@(posedge clk)begin
    dout_valid_rr <= dout_valid_r;
    if(rst)begin
        dout_valid_r <=0;
        state <= 0;
    end
    //else begin    //CHEKC!!!
    else if(din_valid)begin
        if(counter=={2'b00, {$clog2(BUFFER_SIZE){1'b1}}})begin
            state <= 1;
            dout_valid_r <= 1;
        end
        else if(counter == {2'b01, {$clog2(BUFFER_SIZE){1'b1}}})
            state <=0;
        else if(counter == {2'b10, {$clog2(BUFFER_SIZE){1'b1}}})
            state<=2;
        else if(counter == {2'b11, {$clog2(BUFFER_SIZE){1'b1}}})
            state <=0;
    end
end

always@(posedge clk)begin
    if(rst)
        counter <=0;
    else if(din_valid)
        counter <= counter+1;
end

wire signed [DIN_WIDTH:0] feedback_dout_re, feedback_dout_im;
reg signed [DIN_WIDTH:0] feedback_din_re, feedback_din_im=0;
reg feedback_din_valid =0;



always@(posedge clk)begin
    feedback_din_valid <=1; //this doesnt make too much sense here..
    if(state==0)begin
        feedback_din_re <= din_re;
        feedback_din_im <= din_im;
        dout_re_r <= feedback_dout_re;
        dout_im_r <= feedback_dout_im;
    end
    else if(state==1)begin
        feedback_din_re <= $signed(feedback_dout_re)-$signed(din_re);
        feedback_din_im <= $signed(feedback_dout_im)-$signed(din_im);
        dout_re_r <= $signed(feedback_dout_re)+$signed(din_re);
        dout_im_r <= $signed(feedback_dout_im)+$signed(din_im);
    end
    else if(state==2)begin
        feedback_din_re <= $signed(feedback_dout_re)-$signed(din_im);
        feedback_din_im <= $signed(feedback_dout_im)+$signed(din_re);
        dout_re_r <= $signed(feedback_dout_re)+$signed(din_im);
        dout_im_r <= $signed(feedback_dout_im)-$signed(din_re);
    end
end


generate 
    if(DELAY_TYPE=="RAM")begin
        feedback_delay_line #(
            .DIN_WIDTH(2*DIN_WIDTH+2),
            .FIFO_DEPTH(BUFFER_SIZE-3),
            .RAM_PERFORMANCE("HIGH_PERFORMANCE")
        ) feedback_inst (
            .clk(clk),
            .rst(rst),
            .din({feedback_din_re, feedback_din_im}),
            .din_valid(feedback_din_valid),
            .dout({feedback_dout_re, feedback_dout_im}),
            .dout_valid()
        );
    end
    else begin
        delay #(
            .DATA_WIDTH(2*DIN_WIDTH+2),
            .DELAY_VALUE(BUFFER_SIZE-1)
        ) feedback_inst (
            .clk(clk),
            .din({feedback_din_re, feedback_din_im}),
            .dout({feedback_dout_re, feedback_dout_im})
        );
    end
endgenerate


endmodule

