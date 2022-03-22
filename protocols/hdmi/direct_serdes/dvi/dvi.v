`default_nettype none

module dvi #(
    /*ID        Res     Refresh     pxl_freq
      1        640x480    60Hz        25.2MHz
     2,3       720x480    60Hz        27MHz 
    17,18      720x576    50Hz        27MHz
      4       1280x720    60Hz        74.25MHz  
     19       1280x720    50Hz        74.25MHz (?)
     16       1920x1080   60Hz        148.352MHz
     34       1920x1080   30Hz        74.25MHz
    */
    parameter VIDEO_ID_CODE = 1,
    parameter real VIDEO_REFRESH_RATE = 59.94, //harcode the refresh rate.. if not set it would be 
                                               //calculated using the ID_CODE
    parameter BIT_WIDTH = VIDEO_ID_CODE < 4 ? 10 : VIDEO_ID_CODE == 4 ? 11 : 12,
    parameter BIT_HEIGHT = VIDEO_ID_CODE == 16 ? 11: 10
) (
    input wire pxl_clk,
    input wire pxl_clk_x5,
    input wire [23:0] rgb,

    //
    output wire [5:0] phy_tmds_lanes,   //{hdmi0_p,hdmi0_n, ....}
    output wire [1:0] phy_tmds_clk,

    //current position
    output wire [BIT_WIDTH-1:0] cx,
    output wire [BIT_HEIGHT-1:0] cy,

    //sizes
    output wire [BIT_WIDTH-1:0] frame_width,
    output wire [BIT_HEIGHT-1:0] frame_height,
    output wire [BIT_WIDTH-1:0] screen_width,
    output wire [BIT_HEIGHT-1:0] screen_height,
    output wire [BIT_WIDTH-1:0] screen_start_x,
    output wire [BIT_HEIGHT-1:0] screen_start_y
);

wire hsync;
wire vsync;

//generate the given sizes of each format
generate
    case (VIDEO_ID_CODE)
        1:
        begin
            assign frame_width = 800;
            assign frame_height = 525;
            assign screen_width = 640;
            assign screen_height = 480;
            assign hsync = ~(cx >= 16 && cx < 16 + 96);
            assign vsync = ~(cy >= 10 && cy < 10 + 2);
            end
        2, 3:
        begin
            assign frame_width = 858;
            assign frame_height = 525;
            assign screen_width = 720;
            assign screen_height = 480;
            assign hsync = ~(cx >= 16 && cx < 16 + 62);
            assign vsync = ~(cy >= 9 && cy < 9 + 6);
            end
        4:
        begin
            assign frame_width = 1650;
            assign frame_height = 750;
            assign screen_width = 1280;
            assign screen_height = 720;
            assign hsync = cx >= 110 && cx < 110 + 40;
            assign vsync = cy >= 5 && cy < 5 + 5;
        end
        16, 34:
        begin
            assign frame_width = 2200;
            assign frame_height = 1125;
            assign screen_width = 1920;
            assign screen_height = 1080;
            assign hsync = cx >= 88 && cx < 88 + 44;
            assign vsync = cy >= 4 && cy < 4 + 5;
        end
        17, 18:
        begin
            assign frame_width = 864;
            assign frame_height = 625;
            assign screen_width = 720;
            assign screen_height = 576;
            assign hsync = ~(cx >= 12 && cx < 12 + 64);
            assign vsync = ~(cy >= 5 && cy < 5 + 5);
        end
        19:
        begin
            assign frame_width = 1980;
            assign frame_height = 750;
            assign screen_width = 1280;
            assign screen_height = 720;
            assign hsync = cx >= 440 && cx < 440 + 40;
            assign vsync = cy >= 5 && cy < 5 + 5;
        end
        97, 107:
        begin
            assign frame_width = 4400;
            assign frame_height = 2250;
            assign screen_width = 3840;
            assign screen_height = 2160;
            assign hsync = cx >= 176 && cx < 176 + 88;
            assign vsync = cy >= 8 && cy < 8 + 10;
        end
    endcase
    assign screen_start_x = frame_width - screen_width;
    assign screen_start_y = frame_height - screen_height;
endgenerate

//video rate
localparam real VIDEO_RATE = (VIDEO_ID_CODE == 1 ? 25.2E6
    : VIDEO_ID_CODE == 2 || VIDEO_ID_CODE == 3 ? 27.027E6
    : VIDEO_ID_CODE == 4 ? 74.25E6
    : VIDEO_ID_CODE == 16 ? 148.5E6
    : VIDEO_ID_CODE == 17 || VIDEO_ID_CODE == 18 ? 27E6
    : VIDEO_ID_CODE == 19 ? 74.25E6
    : VIDEO_ID_CODE == 34 ? 74.25E6
    : VIDEO_ID_CODE == 97 || VIDEO_ID_CODE == 107 ? 594E6: 0) * (VIDEO_REFRESH_RATE == 59.94 || VIDEO_REFRESH_RATE == 29.97 ? 1000.0/1001.0 : 1);

reg [BIT_WIDTH-1:0] cx_r=0;
reg [BIT_HEIGHT-1:0] cy_r=0;
assign cx = cx_r;
assign cy = cy_r;

always@(posedge pxl_clk)begin
    if(cx_r == (frame_width-1))
        cx_r <=0;
    else
        cx_r <= cx_r+1;
end

always@(posedge pxl_clk)begin
    if(cx_r==(frame_width-1))begin
        if(cy_r == (frame_height-1))
            cy_r <=0;
        else
            cy_r <= cy_r+1;
    end
end


reg [2:0] mode = 1; //video mode
reg [23:0] video_data = 0;
reg [5:0] control_data = 0;
reg [11:0] data_island=0;

reg video_data_period=1;
always@(posedge pxl_clk)
    video_data_period <= ((cx>=screen_start_x) && (cy>=screen_start_y));


//DVI control signals..
always@(pxl_clk)begin
    mode <= video_data_period;
    video_data <= rgb;
    control_data <= {4'd0, {vsync, hsync}}; 
end

genvar i;
wire [29:0] tmds_internal;
generate 

for(i=0; i<3; i=i+1)begin
tmds_encoder #(
    .CHANNEL(i)  
) tmds_encoder_inst(
    .pxl_clk(pxl_clk),
    .video_data(video_data[8*i+:8]),
    .data_island(data_island[4*i+:4]),
    .control_data(control_data[i*2+:2]),
    .mode(mode), 
    .tmds(tmds_internal[10*i+:10])
);
end

endgenerate

hdmi_phy_intf #(
    .CHANNELS(3)
) hdmi_phy_inst (
    .rst(1'b0),
    .pxl_clk(pxl_clk),
    .pxl_clk_x5(pxl_clk_x5), 
    .tmds_internal(tmds_internal),
    .phy_tmds_lane(phy_tmds_lanes),
    .phy_tmds_clk(phy_tmds_clk)
);

endmodule

`default_nettype wire
