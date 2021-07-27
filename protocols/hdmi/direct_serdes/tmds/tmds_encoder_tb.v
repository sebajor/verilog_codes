`default_nettype none
`include "tmds_encoder.v"

module tmds_encoder_tb #(
    parameter CHANNEL =0    //HDMI 1.4a allows 3 types
) (
    input wire pxl_clk,
    input wire [7:0] video_data,
    input wire [3:0] data_island,
    input wire [1:0] control_data,
    input wire [2:0] mode, //0:control,1:video,2:video guard,3:island,4:island guard
    output wire [9:0] tmds
);

tmds_encoder #(
    .CHANNEL(CHANNEL)
) tmds_encoder_inst (
    .pxl_clk(pxl_clk),
    .video_data(video_data),
    .data_island(data_island),
    .control_data(control_data),
    .mode(mode),
    .tmds(tmds)
);

initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end

endmodule
