`default_nettype none

module send_msg #(
    parameter MSG_LEN = 26,
    parameter N_BITS = 8
) (
    input wire clk,
    input wire rst,
    input wire start_trans,
    output wire [N_BITS-1:0] uart_tdata,
    output wire uart_tvalid,
    input wire uart_tready,

    input wire [N_BITS-1:0] msg,
    output wire [$clog2(MSG_LEN)-1:0] msg_index
);
    reg start_msg = 0;
    always@(posedge clk)begin
        if(rst)
            start_msg<= 0;
        else begin
            if(start_trans)
                start_msg <= 1;
            else
                start_msg <= start_msg;
        end
    end

    reg [$clog2(MSG_LEN)-1:0] r_msg_index;
    reg [N_BITS-1:0] r_uart_tdata =0;
    reg d_uart_tready= 0;
    reg r_uart_tvalid=0;
    reg [2:0] count_wait = 0;

    always@(posedge clk)begin
        if(rst) begin
            r_msg_index <= 0;
            r_uart_tvalid <= 0;
        end
        else begin
            if(start_msg & (r_msg_index<MSG_LEN) &uart_tready) begin
                if((&count_wait))begin
                    r_uart_tdata <= msg;
                    r_msg_index <= r_msg_index+1;
                    r_uart_tvalid <= 1;
                    count_wait <=0;
                end
                else begin
                    r_msg_index <= r_msg_index;
                    r_uart_tdata <= r_uart_tdata;
                    r_uart_tvalid <= 0;
                    count_wait <= count_wait+1;
                end
            end
            else begin
                r_uart_tvalid <=0;
                r_msg_index <= r_msg_index;
                r_uart_tdata <= r_uart_tdata;
            end
        end
    end

    assign uart_tdata = r_uart_tdata;
    assign uart_tvalid = r_uart_tvalid;
    assign msg_index = r_msg_index;

endmodule



