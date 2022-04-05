module iverilog_dump();
initial begin
    $dumpfile("traces.fst");
    $dumpvars();
end
endmodule
