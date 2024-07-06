`default_nettype none

module feedback_line #(
    parameter DIN_WIDTH = 16,
    parameter FEEDBACK_SIZE= 32,
    parameter DELAY_TYPE = "delay" //delay or bram
) (
    input wire clk,
    input wire [DIN_WIDTH-1:0] din,
    output wire [DIN_WIDTH-1:0] dout
);


generate 
    if(DELAY_TYPE == "bram")begin
        //to test!!!!
        fifo_sync #(
            .DIN_WIDTH(DIN_WIDTH),
            .FIFO_DEPTH(FEEDBACK_SIZE),
            .RAM_PERFORMANCE("LOW_LATENCY")
        ) delay_feedback_inst (
            .clk(clk),
            .rst(0),
            .wdata(din),
            .w_valid(1'b1),
            .full(),
            .empty(),
            .rdata(dout),
            .r_valid(),
            .read_req(1'b1)
        );
    end
    else begin
        delay #(
            .DATA_WIDTH(DIN_WIDTH),
            .DELAY_VALUE(FEEDBACK_SIZE)
        ) delay_feedback_inst (
            .clk(clk),
            .din(din),
            .dout(dout)
        );
    end
endgenerate


endmodule


