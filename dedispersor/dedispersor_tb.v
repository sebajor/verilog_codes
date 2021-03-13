`default_nettype none
`include "dedispersor.v"

module dedispersor_tb #(
    //parameter N_CHANNELS=8, //pow of 2
    //parameter [32*N_CHANNELS-1:0] DELAY_ARRAY ={32'd2,32'd3,32'd4,32'd5,32'd6,32'd7,32'd8,32'd9},
    
    parameter N_CHANNELS=64, //pow of 2
    parameter [32*N_CHANNELS-1:0] DELAY_ARRAY ={32'd2,32'd3,32'd4,32'd5,32'd6,32'd7,32'd8,32'd9, 
                                                32'd10,32'd11,32'd12,32'd13,32'd14,32'd15,32'd16,32'd17,32'd18,32'd19,32'd20,32'd21,32'd22,32'd23,32'd24,32'd25,
                                                32'd26,32'd27,32'd28,32'd29,32'd30,32'd31,32'd32,32'd33,32'd34,32'd35,32'd36,32'd37,32'd38,32'd39,32'd40,32'd41,
                                                32'd42,32'd43,32'd44,32'd45,32'd46,32'd47,32'd48,32'd49,32'd50,32'd51,32'd52,32'd53,32'd54,32'd55,32'd56,32'd57,
                                                32'd58,32'd59,32'd60,32'd61,32'd62,32'd63,32'd64,32'd65},

    parameter DIN_WIDTH = 32
) (
    input wire clk,
    input wire ce,
    input wire rst,
    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,
    output wire [DIN_WIDTH-1:0] dout,
    output wire dout_valid
);



dedispersor #(
    .N_CHANNELS(N_CHANNELS),
    .DELAY_ARRAY(DELAY_ARRAY),
    .DIN_WIDTH(DIN_WIDTH)
) dedispersor_inst (
    .clk(clk),
    .ce(ce),
    .rst(rst),
    .din(din),
    .din_valid(din_valid),
    .dout(dout),
    .dout_valid(dout_valid)
);

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end

endmodule
