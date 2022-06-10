`default_nettype none

module arte_beamform #(
    parameter DIN_WIDTH = 18,
    parameter FFT_SIZE = 2048,
    parameter PARALLEL = 4,
    parameter COMPLEX_ADD_DELAY = 0,
    parameter POST_FLAG_DELAY = 0,
    parameter RFI_OUT_DELAY = 0,    
    parameter POWER_SHIFT = 0,
    parameter POWER_DELAY = 0,
    parameter POWER_WIDTH = 18,
    parameter POWER_POINT = 17,
    parameter DEBUG = 1
)(

    input wire clk,
    
    input wire sync_in,
    input wire [PARALLEL*DIN_WIDTH-1:0] fft0_re, fft0_im, fft1_re, fft1_im,
    
    //fft flagging configuration
    input wire [31:0] config_flag,
    input wire [31:0] config_num,
    input wire config_en,

    //post flag output, these goes into the rfi subsystem
    output wire [PARALLEL*DIN_WIDTH-1:0] sig_flag_re, sig_flag_im,
    output wire sig_sync,

    //for debugging    
    output wire cast_warning,
    output wire [POWER_WIDTH*PARALLEL-1:0] power_resize,
    output wire sync_pow_resize
);


localparam DIN_POINT = DIN_WIDTH-1;

genvar i;
reg [PARALLEL*(DIN_WIDTH+1)-1:0] beam_re_temp=0, beam_im_temp=0;
reg sync_r=0;

wire [PARALLEL*(DIN_WIDTH)-1:0] beam_re, beam_im;

generate 
    for(i=0; i<PARALLEL; i=i+1)begin: complex_add
        always@(posedge clk)begin
            sync_r <= sync_in;
            beam_re_temp[(DIN_WIDTH+1)*i+:DIN_WIDTH+1] <= 
                $signed(fft0_re[DIN_WIDTH*i+:DIN_WIDTH])+$signed(fft1_re[DIN_WIDTH*i+:DIN_WIDTH]);
            beam_im_temp[(DIN_WIDTH+1)*i+:DIN_WIDTH+1] <= 
                $signed(fft0_im[(DIN_WIDTH)*i+:DIN_WIDTH])+$signed(fft1_im[DIN_WIDTH*i+:DIN_WIDTH]);
        end
        assign beam_re[DIN_WIDTH*i+:DIN_WIDTH] = $signed(beam_re_temp[(DIN_WIDTH+1)*i+:DIN_WIDTH+1]);
        assign beam_im[DIN_WIDTH*i+:DIN_WIDTH] = $signed(beam_im_temp[(DIN_WIDTH+1)*i+:DIN_WIDTH+1]);
    end
endgenerate


//complex add delay
wire [PARALLEL*DIN_WIDTH-1:0] beam_re_r, beam_im_r;
wire sync_rr;
delay #(
    .DATA_WIDTH(2*PARALLEL*DIN_WIDTH+1),
    .DELAY_VALUE(COMPLEX_ADD_DELAY)
) complex_add_delay (
    .clk(clk),
    .din({beam_re, beam_im, sync_r}),
    .dout({beam_re_r, beam_im_r, sync_rr})
);

//flag channels

wire [PARALLEL*DIN_WIDTH-1:0] beam_flag_re, beam_flag_im;
wire sync_flag;

fft_chann_flag #(
    .STREAMS(PARALLEL),
    .FFT_SIZE(FFT_SIZE),
    .DIN_WIDTH(DIN_WIDTH)
) fft_channel_flag [1:0] (
    .clk(clk),
    .sync_in(sync_rr),
    .din({beam_re_r, beam_im_r}),
    .sync_out(sync_flag),
    .dout({beam_flag_re, beam_flag_im}),
    .config_flag(config_flag),
    .config_num(config_num),
    .config_en(config_en)
);

//flag for the rfi subsystem
wire [PARALLEL*DIN_WIDTH-1:0] beam_flag_re_r, beam_flag_im_r;
wire sync_flag_r;

delay #(
    .DATA_WIDTH(2*PARALLEL*DIN_WIDTH+1),
    .DELAY_VALUE(RFI_OUT_DELAY)
) rfi_out_delay (
    .clk(clk),
    .din({beam_flag_re, beam_flag_im, sync_flag}),
    .dout({sig_flag_re, sig_flag_im, sig_sync})
);

//flag delay
delay #(
    .DATA_WIDTH(2*PARALLEL*DIN_WIDTH+1),
    .DELAY_VALUE(POST_FLAG_DELAY)
) flag_delay_inst (
    .clk(clk),
    .din({beam_flag_re, beam_flag_im, sync_flag}),
    .dout({beam_flag_re_r, beam_flag_im_r, sync_flag_r})
);

//fft power 
wire [PARALLEL*(2*DIN_WIDTH+1)-1:0] beam_power;
wire sync_power;

delay #(
    .DATA_WIDTH(1),
    .DELAY_VALUE(5)
) power_delay_sync_inst (
    .clk(clk),
    .din(sync_flag_r),
    .dout(sync_power)
);

genvar j;
generate
    for(j=0; j<PARALLEL; j=j+1)begin: complex_power_loop
    complex_power #(
        .DIN_WIDTH(DIN_WIDTH)
    ) beam_power_inst (
        .clk(clk),
        .din_re(beam_flag_re_r[DIN_WIDTH*j+:DIN_WIDTH]),
        .din_im(beam_flag_im_r[DIN_WIDTH*j+:DIN_WIDTH]),
        .din_valid(1'b1),
        .dout(beam_power[(2*DIN_WIDTH+1)*j+:2*DIN_WIDTH+1]),
        .dout_valid()
    );


    end
endgenerate


resize_module #(
    .DIN_WIDTH(2*DIN_WIDTH+1),
    .DIN_POINT(2*DIN_POINT),
    .DATA_TYPE("unsigned"),  //signed or unsigned
    .PARALLEL(PARALLEL),
    .SHIFT(POWER_SHIFT),    //negative >>, positive <<
    .DELAY(POWER_DELAY),
    .DOUT_WIDTH(POWER_WIDTH),
    .DOUT_POINT(POWER_POINT),
    .DEBUG(DEBUG)
) resize_power_inst (
    .clk(clk), 
    .din(beam_power),
    .din_valid(1'b1),
    .sync_in(sync_power),
    .dout(power_resize),
    .dout_valid(),
    .sync_out(sync_pow_resize),
    .warning(cast_warning)
);


endmodule
