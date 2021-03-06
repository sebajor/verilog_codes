module uart_tx_tb;
    reg clk, axis_tvalid;
    reg [7:0] axis_tdata;
    wire axis_tready;
    wire tx_data;

    uart_tx uart_tx(.axis_tdata(axis_tdata), .axis_tvalid(axis_tvalid), .axis_tready(axis_tready), .clk(clk), .tx_data(tx_data));

    initial begin
        $from_myhdl(clk, axis_tvalid, axis_tdata);
        $to_myhdl(axis_tready, tx_data);
    end

    initial begin
        $dumpfile("uart_tx_tb.vcd");
        $dumpvars();
    end
endmodule
