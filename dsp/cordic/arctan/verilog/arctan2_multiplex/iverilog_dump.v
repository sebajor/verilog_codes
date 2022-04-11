module iverilog_dump();
initial begin
    $dumpfile("traces.vcd");
    $dumpvars();
end
endmodule
