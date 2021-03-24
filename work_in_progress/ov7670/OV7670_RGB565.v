`default_nettype none 


module OV7670_RGB565 (
    input wire pclk,
    input wire vsync,
    input wire href,
    input wire [7:0] pdata,

    output reg [15:0] pxl_data = 0,
    output reg pxl_valid = 0,
    output reg frame_done = 0,
    output reg [18:0] pxl_addr =0   //clog2(640*480)
);



localparam WAIT_SOF = 0;
localparam ROW_CAPT = 1;

reg [1:0] fsm_state =WAIT_SOF;
reg pxl_half=0;

always@(posedge pclk)begin
    case(fsm_state)
        WAIT_SOF: begin
            fsm_state <= (!vsync) ? ROW_CAPT : WAIT_SOF;
            frame_done <= 0;
            pxl_half <= 0;
            pxl_addr <= 0;
        end
        ROW_CAPT: begin
            fsm_state <= vsync ? WAIT_SOF : ROW_CAPT;
            frame_done <= vsync ? 1:0;
            pxl_valid <= (href &&pxl_half) ? 1:0;
            if(href)begin
                pxl_half <= ~pxl_half;
                if(pxl_half)
                    pxl_data[7:0] <= pdata;
                else begin
                    pxl_data[15:8] <= pdata;
                    pxl_addr <= pxl_addr+1;
                end
            end
        end
    endcase
end
endmodule
