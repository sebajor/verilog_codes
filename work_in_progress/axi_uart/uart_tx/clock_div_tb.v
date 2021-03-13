module clock_div_tb;

reg clk_in;
wire clk_out;

clock_divider clk_divider(.clk_in(clk_in), .clk_out(clk_out));


initial begin
    $from_myhdl(clk_in);
    $to_myhdl(clk_out);
end

initial begin
    $dumpfile("clk_div.vcd");
    $dumpvars();
end
endmodule


