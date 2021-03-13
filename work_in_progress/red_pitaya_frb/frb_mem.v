`default_nettype none


module frb_mem #(
    parameter N_ADDR = 1024,
    parameter DATA_WIDTH = 32,
    parameter INIT_VALS = "trig.mem"
) (
    input w_clk,
    input wen,
    input [$clog2(N_ADDR)-1:0] waddr,
    input [DATA_WIDTH-1:0] win,

    input r_clk,
    input ren,
    input [$clog2(N_ADDR)-1:0] raddr,
    output reg [DATA_WIDTH-1:0] rout 
);
    reg [DATA_WIDTH-1:0] mem [N_ADDR-1:0];
    initial begin
        $readmemh(INIT_VALS, mem);
    end
    
    always@(posedge w_clk) begin
        if(wen)begin
            mem[waddr] <= win;
        end
    end

    always@(posedge r_clk)begin
        if(ren)begin
            rout<= mem[raddr]; 
        end
    end

endmodule 
