module uart_rs;

reg clk, tx_data, rst;
wire [7:0] data;
wire valid;

uart_rx uart_rx(.clk(clk), .rst(rst), .tx_data(tx_data), .data(data), .valid(valid));

initial begin 
    $from_myhdl(clk,rst,tx_data);
    $to_myhdl(valid, data);
end

initial begin
   $dumpfile("uart_rx_tb.vcd");
   $dumpvars();
end 
endmodule
