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

reg [DIN_WIDTH-1:0] x0=0, y0=0;
reg [DIN_WIDTH-1:0] x_actual=0, y_actual=0;


reg [$clog2(BIT_WIDTH)-1:0] x_counter=0;
reg [$clog2(BIT_HEIGHT)-1:0] y_counter=0;
reg [31:0] x_step_r=0, y_step_r=0;
reg [31:0] ram_counter=0;

//mandelbrot pixel signals
reg pxl_finish=0, pxl_din_valid=0;
wire pxl_busy;
wire pxl_dout_valid;


always@(posedge clk)begin
    if(rst)begin
        pxl_din_valid <=1; 
        x_counter <= 0; y_counter <=0;
    end
    else begin
        if(pxl_dout_valid)begin
            pxl_din_valid <= ~pxl_finish;
            if(x_counter==(BIT_WIDTH-1))begin
                x_counter <= 0;
                y_counter <= y_counter+1;
            end 
            else
                x_counter <= x_counter+1;
        end
        else
            pxl_din_valid <= 0;
    end
end

always@(posedge clk)begin
    if(rst)begin
        ram_counter <= 0;
        pxl_finish <=0;
    end
    else if(pxl_dout_valid)begin
        if(ram_counter == (BIT_WIDTH*BIT_HEIGHT/N_COMP-1))
            pxl_finish <=1;
        else
            ram_counter <= ram_counter+1;
    end
end



always@(posedge clk)begin
    if(rst)begin
        x0 <= x_i; y0<=y_i+y_step*LINE_INDEX;
        x_actual <= x_i; y_actual <= y_i+y_step*LINE_INDEX;
        x_step_r <= x_step; y_step_r <= y_step;
    end
    else begin
        if(pxl_dout_valid)begin
            if(x_counter==(BIT_WIDTH-1))begin
                x_actual <= x0;
                y_actual <= y_actual+y_step_r*(N_COMP);
            end
            else
                x_actual <= x_actual+x_step_r;
        end
    end
end

//madelbrot pxl
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
    .din_valid(pxl_din_valid),
    .busy(pxl_busy),
    .dout(pxl_calc),
    .dout_valid(pxl_dout_valid)
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
    .c_re(x_actual), 
    .c_im(y_actual),
    .iters(iters),
    .din_valid(pxl_din_valid),
    .busy(pxl_busy),
    .dout(pxl_calc),
    .dout_valid(pxl_dout_valid)
);
end
endgenerate

//ram address multiplex
reg [RAM_ADDR-1:0] ram_addr;
always@(*)begin
    if(pxl_finish)begin
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
    .wea(pxl_dout_valid),
    .ena(1'b1),
    .rsta(1'b0),
    .regcea(),
    .douta(dout)
);

assign line_rdy = pxl_finish;

endmodule
