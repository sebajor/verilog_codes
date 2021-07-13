`default_nettype none

/* The default is 25mhz as input clk
  we are going to target mclk= 12.28mhz, lrck=96khz, ie x128 in the 
  chart https://reference.digilentinc.com/reference/pmod/pmodi2s2/reference-manual
  for that mclk=clk_in/2; lrck=clk_in/256 and sclk=clk_in/4
  (I would think that you could modify the parameters to get the i2s pmod 
  work in other configuration, but I havent test it)

  The i2s protocol present the data in the data in the falling edge of sclk.
  The data is in 2 complement and the msb is presented first.
  The change of the lrck occurs in the lsb of the previous word. 

  Is recommended to use a oddr at the output clocks (Some people argue 
  that driving the clock without oddr gives you a bad routing in the clock
  tree).
*/

module i2s_pmod_v2 #(
    parameter CLK_FREQ = 25_000_000,
    parameter MCLK_DEC = 1,         //2**MCLK_DEC decimation factor of mclk
    parameter LRCK_DEC = 8,         //2**LRCK_DEC decimation factor of lrck
    parameter SCLK_DEC = 2          //2**SCLK_DEC decimation factor of sclk
) (
    input wire clk,
    
    //adc fpga interfaces
    //valid 0:right, 1:left
    output wire [31:0] adc_r_tdata,
    output wire [31:0] adc_l_tdata,
    output wire [1:0]  adc_tvalid,
    input  wire [1:0]  adc_tready,

    //dac fpga interfaces
    //valid 0:rigth, 1:left
    input  wire [31:0] dac_r_tdata,
    input  wire [31:0] dac_l_tdata,
    input  wire [1:0]  dac_tvalid,
    output wire [1:0]  dac_tready,

    //physical interfaces
    output wire dac_mclk,
    output wire dac_lrck,
    output wire dac_sclk,
    output wire dac_sdat,

    output wire adc_mclk,
    output wire adc_lrck,
    output wire adc_sclk,
    input  wire adc_dat 
);

reg [LRCK_DEC:0] counter=0; //counter has one more bit to count
                            //l and r with the same counter;
always@(posedge clk)begin
    counter <= counter+1;
end

//clock assignations
assign dac_mclk = counter[MCLK_DEC-1];
assign dac_lrck = counter[LRCK_DEC-1];
assign dac_sclk = counter[SCLK_DEC-1];

assign adc_mclk = counter[MCLK_DEC-1];
assign adc_lrck = counter[LRCK_DEC-1];
assign adc_sclk = counter[SCLK_DEC-1];

//delay in the lrck to detect the edges
reg lrck_dly=1'b0;
always@(posedge clk)begin
    lrck_dly <= adc_lrck;
end


//dac axi stream handshakes
reg [1:0] dac_tready_r = 2'b11;
assign dac_tready = dac_tready_r;
reg [63:0] dac_r_shift=0, dac_l_shift=0;

always@(posedge clk)begin
    if(|dac_tvalid && |dac_tready_r)begin
        if(dac_tready_r[0] && dac_tvalid[0])begin
            dac_r_shift[31:0] <= dac_r_tdata;
            dac_tready_r[0] <= 1'b0;
        end
        if(dac_tready_r[1] && dac_tvalid[1])begin
            dac_l_shift[31:0] <= dac_l_tdata;
            dac_tready_r[1] <= 1'b0;
        end
    end
    else if(~adc_lrck && lrck_dly)begin
        //falling edge, ie end of rigth channel frame
        dac_tready_r[0] <= 1'b1;
        dac_r_shift <= {dac_r_shift[31:0], 32'b0};
    end    
    else if(adc_lrck && ~lrck_dly)begin
        //rising edge, ie end of left channel frame
        dac_tready_r[1]<= 1'b1;
        dac_l_shift <= {dac_l_shift[31:0], 32'b0};
    end
    else begin
        dac_tready_r <= dac_tready;
        dac_l_shift <= dac_l_shift;
        dac_r_shift <= dac_r_shift;
    end
end

//shift the data out
//we have to update the data in the falling edge of the sclk so
//thats when &counter[SCLK_DEC-1:0], also the index of the data 
//would be given by counter[SCLK_DEC+:5] 
reg dac_out=0;
assign dac_sdat = dac_out;
wire [5:0] index;
assign index = 63-counter[SCLK_DEC+:5];
wire sdat_update;
assign sdat_update= &counter[SCLK_DEC-1:0];

always@(posedge clk)begin
    if(sdat_update)begin
        if(dac_lrck)
            dac_out <= dac_l_shift[index];
        else
            dac_out <= dac_r_shift[index];
    end
    else
        dac_out <= dac_out;
end

//the dac part seems to be working as expected

//adc part
//synchronizer
//first we need to delay one sclk cycle lrck(to match the lsb)
reg [SCLK_DEC-1:0] lrck_dly_2=0;
always@(posedge clk)begin
    lrck_dly_2 <= {lrck_dly_2[SCLK_DEC-2:0], adc_lrck};
end



reg [2:0] sync_adc_dat = 3'b0, adc_sclk_dly = 3'b0, adc_lrck_dly=3'b0;
always@(posedge clk)begin
    sync_adc_dat <= {sync_adc_dat[1:0], adc_dat};
    adc_sclk_dly <= {adc_sclk_dly[1:0], adc_sclk};
    adc_lrck_dly <= {adc_lrck_dly[1:0], lrck_dly_2[SCLK_DEC-1]};
end

//in this case we have to sample in the rising edge of the sclk
//because in that part the data is stable

reg [63:0] adc_l_shift=0, adc_r_shift=0;
always@(posedge clk)begin
    if(~adc_sclk_dly[2]&&adc_sclk_dly[1])begin
        if(adc_lrck_dly[2])
            adc_r_shift <= {adc_r_shift[62:0], sync_adc_dat[2]};
        else
            adc_l_shift <= {adc_l_shift[62:0], sync_adc_dat[2]};
    end
    else begin
        adc_r_shift <= adc_r_shift;
        adc_l_shift <= adc_l_shift;
    end
end

//axi handshake
//the data is valid when we are sapmling the msb of the next frame
reg [1:0] adc_tvalid_r = 2'b0;
assign adc_tvalid = adc_tvalid_r;
reg [31:0] adc_r_tdata_r=0, adc_l_tdata_r=0;
assign adc_r_tdata = adc_r_tdata_r;
assign adc_l_tdata = adc_l_tdata_r;

always@(posedge clk)begin
    if(adc_lrck_dly[2]&& ~adc_lrck_dly[1])begin
        //rising edge, the left channel is ready
        adc_l_tdata_r <= adc_l_shift[63:32];
        adc_tvalid_r[1] <= 1'b1;
    end
    else if(~adc_lrck_dly[2] && adc_lrck_dly[1])begin
        //falling edge, the right channel is ready
        adc_r_tdata_r <= adc_r_shift[63:32];
        adc_tvalid_r[0] <= 1'b1;
    end
    else begin
        adc_r_tdata_r <= adc_r_tdata_r;
        adc_l_tdata_r <= adc_l_tdata_r;
        if(adc_tvalid[0]&&adc_tready[0])
            adc_tvalid_r[0] <= 1'b0;
        if(adc_tvalid[1]&&adc_tready[1])
            adc_tvalid_r[1] <= 1'b0;
    end
end





endmodule
