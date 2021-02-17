`default_nettype none

/*  module to be used with the pmod in slave mode
    it gives 24 bit data 
    The recommended and tested parameters are mclk_freq 25 and
    dvider factor 9, I think it should work with other parameters
    but hadnt test it
*/

module i2s_pmod #(
    parameter MCLK_FREQ = 25_000_000,
    parameter DIVIDER_FACTOR = 9    //2**divide factor
)(
    input wire clk,

    //output wire [63:0] adc_tdata, //[63:32] left, [31:0] rigth
    output wire [31:0] adc_r_tdata,
    output wire [31:0] adc_l_tdata,
    output wire [1:0] adc_tvalid,
    input wire [1:0] adc_tready,

    //left and right chanels 
    input wire [63:0] dac_tdata,
    input wire dac_tvalid,
    output wire dac_tready,

    //physical interfaces
    output wire dac_mclk,
    output wire dac_lrck,
    output wire dac_sclk, //i think is not required
    output wire dac_sdat,

    output wire adc_mclk,
    output wire adc_lrck,
    output wire adc_sclk,
    input  wire adc_dat
);

reg [DIVIDER_FACTOR-1:0] counter=0;
reg sclk_dly=0;

always@(posedge clk)begin
    counter <= counter+1;
end

always@(posedge clk)begin
    sclk_dly <= counter[DIVIDER_FACTOR-1];
end


//clock generators
//the right thing to do is to use a oddr for the output mclk
//but i want to test it in the go board, when moving to the
// xilinx board fix this or not

assign dac_mclk = clk;
assign dac_lrck = counter[DIVIDER_FACTOR-1];
assign dac_sclk = counter[DIVIDER_FACTOR-7];

assign dac_mclk = clk;
assign adc_lrck = counter[DIVIDER_FACTOR-1];
assign adc_sclk = counter[DIVIDER_FACTOR-7];

//dac axi stream handshakes
reg dac_tready_r =1; 
assign dac_tready = dac_tready_r;

reg [63:0] dac_data=0;

always@(posedge clk)begin
    if(dac_tvalid && dac_tready_r)begin
        dac_tready_r <= 0;
        dac_data <= dac_tdata;
    end
    else if(~counter[DIVIDER_FACTOR-1] & sclk_dly)begin
        dac_tready_r <= 1;
    end
end





reg flag = 0;
reg [31:0] dac_r=0, dac_l=0;
always@(posedge clk)begin
    if(dac_tvalid && dac_tready_r)
        flag <= 1;
    else if(counter=={(DIVIDER_FACTOR-6){1'b1}} && flag) begin
        flag <= 0;
        dac_r <= dac_data[31:0];
        dac_l <= dac_data[63:32];
    end
    else begin
        flag <= flag;
        dac_r <= dac_r;
        dac_l <= dac_l;
    end
end

//shift data out
//we update the data in the 3'b111 which correspond to the falling
//edge of sclk


reg [63:0] dac_r_shift=0, dac_l_shift=0;
always@(posedge clk)begin
    if(counter=={(DIVIDER_FACTOR-6){1'b1}}) begin
        if(flag)begin
            dac_r_shift[31:0] <= dac_r;
            dac_l_shift[31:0] <= dac_l;
        end
    end
    else if(counter==0)begin
        dac_r_shift <= {dac_r_shift[31:0], 32'b0};
        dac_l_shift <= {dac_l_shift[31:0], 32'b0};
    end
end

reg dac_out=0;
assign dac_sdat = dac_out;

always@(posedge clk)begin
    if(counter[DIVIDER_FACTOR-7:0]=={(DIVIDER_FACTOR-6){1'b1}})begin
        if(dac_lrck)
            dac_out <= dac_l_shift[32+counter[DIVIDER_FACTOR-2-:5]];
        else
            dac_out <= dac_r_shift[32+counter[DIVIDER_FACTOR-2-:5]];
    end
    else begin
        dac_out <= dac_out;
    end
end

//adc part

//synchronizer
reg [2:0] sync_adc_dat=4'b0;
always@(posedge clk)
    sync_adc_dat <= {sync_adc_dat[1:0], adc_dat};

reg [31:0] adc_l_shift=0, adc_r_shift=0;

//check!
always@(posedge clk)begin
    //like  have a 3 delay for the synchronizer //check 
    if(counter[DIVIDER_FACTOR-7:0]=={(DIVIDER_FACTOR-6){1'b1}})begin
        if(adc_lrck)
            adc_r_shift <= {adc_r_shift[31:1], sync_adc_dat[2]};
        else
            adc_l_shift <= {adc_l_shift[31:1], sync_adc_dat[2]};
    end
end

//axi signals
reg [1:0] adc_tvalid_r=2'b0;
assign adc_tvalid = adc_tvalid_r;

reg [31:0] adc_l_tdata_r=0, adc_r_tdata_r=0;
assign adc_l_tdata = adc_l_tdata_r;
assign adc_r_tdata = adc_r_tdata_r;
always@(posedge clk)begin
    if(counter[DIVIDER_FACTOR-7:0]=={(DIVIDER_FACTOR-6){1'b1}})begin
        if(adc_lrck)begin
            adc_r_tdata_r <= adc_r_shift;
            adc_tvalid_r[0] <= 1;
        end
        else begin
            adc_l_tdata_r <= adc_l_tdata;
            adc_tvalid_r[1] <= 1;
        end
    end
    else begin
        if(adc_tready[0] | adc_tready[1])begin
            adc_tvalid_r <= ~adc_tready;
        end
        else begin
            adc_tvalid_r <= adc_tvalid_r;
            adc_l_tdata_r <= adc_l_tdata_r;
            adc_r_tdata_r <= adc_r_tdata_r;
        end
    end
end

endmodule
