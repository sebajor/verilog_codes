module prog_shift #(
    parameter IN_WIDTH = 8,
    parameter OUT_WIDTH = 4,
    parameter N_INPUTS = 24
) (
    input wire [IN_WIDTH*N_INPUTS-1:0]  in_data,
    input wire [$clog2(IN_WIDTH)-1:0]   index,
    input wire                          clk,
    input wire                          ce,
    output wire [OUT_WIDTH*N_INPUTS-1:0] out_data
);
    
    reg [OUT_WIDTH*N_INPUTS-1:0] dout=0;
    integer i;
    always@(posedge clk)begin
        for(i=0; i<N_INPUTS; i=i+1)begin
            dout[OUT_WIDTH*i+:OUT_WIDTH] <= (in_data[IN_WIDTH*i+:IN_WIDTH]>>index); 
        end
    end
    
    assign out_data = dout;
    
endmodule 

