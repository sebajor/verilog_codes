`default_nettype none

module mandelbrot_line #(
    parameter BIT_WIDTH = 640,
    parameter BIT_HEIGHT = 480,
    parameter DIN_WIDTH = 32,
    parameter DIN_POINT = 12,
    parameter N_COMP = 4,
    parameter LINE_INDEX =0,
    parameter TYPE = "CUSTOM"    //"BASIC" or "CUSTOM"
) (
    input wire clk,
    input wire rst,
    //parameters
    input wire signed [DIN_WIDTH-1:0] x_i,
    input wire [31:0] x_step,
    input wire signed [DIN_WIDTH-1:0] y_i,
    input wire [31:0] y_step,
    input wire [31:0] iters,
    input wire [DIN_WIDTH-1:0] c_re, c_im,

    //display ports
    output wire [DIN_WIDTH-1:0] dout,
    input wire [$clog2(BIT_WIDTH)-1:0] cx, 
    input wire [$clog2(BIT_HEIGHT)-1:0] cy,
    output wire line_rdy
);

localparam RAM_ADDR = $clog2(BIT_WIDTH*BIT_HEIGHT/N_COMP);

reg [DIN_WIDTH-1:0] x0=0, x_actual=0, x_next=0;
reg [DIN_WIDTH-1:0] y0=0, y_actual=0, y_next=0;
reg [31:0] x_step_r=0, y_step_r=0;

reg [31:0] x_counter=0, y_counter=0;
reg [RAM_ADDR-1:0] ram_counter=0;
reg pxl_calc_finish=0, pxl_calc_in_valid=0;

wire pxl_calc_busy;
wire pxl_calc_dout_valid;


always@(posedge clk)begin
    if(rst)begin
        x0 <= x_i;  y0 <= y_i+LINE_INDEX;
        x_step_r <= x_step; y_step_r <= y_step;
        x_actual <= x_i; y_actual<=y_i;
        x_counter<=0; y_counter <=0;
        pxl_calc_in_valid <=1;
    end
    else begin
        x_actual <= x_next;
        y_actual <= y_next;
        if(~pxl_calc_busy)begin
            pxl_calc_in_valid <=0;
        end
        if(pxl_calc_dout_valid)begin
            if(x_counter==(BIT_WIDTH-1))begin
                x_counter <= 0;
                y_counter <= y_counter+1;
            end
            else begin
                x_counter <= x_counter+1;
            end
        end
        else begin
            //check!!!
            pxl_calc_in_valid <= ~pxl_calc_finish;
        end
    end
end

//ram 
always@(posedge clk)begin
    if(rst)begin
        ram_counter <=0;
        pxl_calc_finish <= 0;
    end
    else if(pxl_calc_dout_valid)begin
        //ram counter index
        if(ram_counter==(BIT_WIDTH*BIT_HEIGHT/N_COMP-1))
            pxl_calc_finish <= 1;
        else
            ram_counter <= ram_counter+1;
    end
end

//next pxl position calculation
always@(posedge clk)begin
    if(rst)begin
        x_next <= x_i+x_step;
        y_next <= y_i+LINE_INDEX;
    end
    else if(pxl_calc_dout_valid)begin
        if(x_counter==(BIT_WIDTH-1))begin
            //check the condition!
            y_next <= y_next+y_step*N_COMP;
            x_next <= x0;
        end
        else begin
            x_next <= x_next+x_step;
        end
    end
end

wire [31:0] pxl_calc; 

generate
if(TYPE=="CUSTOM")begin
mandelbrot_pxl #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT)
) mandelbrot_pxl_inst (
    .clk(clk),
    .x_init(x_actual),
    .y_init(y_actual),
    .c_re(c_re),    //if I want the typical mandelbrot plot this is x_actual
    .c_im(c_im),    //and this one y_actual
    .iters(iters),
    .din_valid(pxl_calc_in_valid),
    .busy(pxl_calc_busy),
    .dout(pxl_calc),
    .dout_valid(pxl_calc_dout_valid)
);
end
else begin
mandelbrot_pxl #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT)
) mandelbrot_pxl_inst (
    .clk(clk),
    .x_init(x_actual),
    .y_init(y_actual),
    .c_re(x_actual),    //if I want the typical mandelbrot plot this is x_actual
    .c_im(y_actual),    //and this one y_actual
    .iters(iters),
    .din_valid(pxl_calc_in_valid),
    .busy(pxl_calc_busy),
    .dout(pxl_calc),
    .dout_valid(pxl_calc_dout_valid)
);


end
endgenerate

reg [RAM_ADDR-1:0] ram_addr;
always@(*)begin
    if(pxl_calc_finish)begin
        ram_addr = cx+cy[$clog2(BIT_HEIGHT)-1:$clog2(N_COMP)]*BIT_WIDTH;
    end
    else begin
        ram_addr = ram_counter;
    end
end


single_port_ram #(
    .RAM_WIDTH(32),
    .RAM_DEPTH(BIT_WIDTH*BIT_HEIGHT/N_COMP),
    .RAM_PERFORMANCE("LOW_LATENCY"),
    .INIT_FILE("")
) ram_inst (
    .addra(ram_addr),
    .dina(pxl_calc),
    .clka(clk),
    .wea(pxl_calc_dout_valid & ~pxl_calc_finish),
    .ena(1'b1),
    .rsta(1'b0),
    .regcea(),
    .douta(dout)
);

assign line_rdy = pxl_calc_finish;

endmodule
