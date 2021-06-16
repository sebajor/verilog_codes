dut=delay_tree
verilog_source= $(dut)_tb.v

sim:
	$(shell iverilog -o $(dut)_out $(verilog_source)) 
	$(shell ./$(dut)_out )

clean:
	rm $(dut)_out
	rm traces.vcd
