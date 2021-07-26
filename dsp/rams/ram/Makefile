dut=async_true_dual_ram
SIM=icarus
TOPLEVEL_LANG = verilog
VERILOG_SOURCES = $(shell pwd)/$(dut)_tb.v
TOPLEVEL = $(dut)_tb
MODULE = $(dut)_test 

include $(shell cocotb-config --makefiles)/Makefile.sim

clean::
	@rm -rf *.del
	@rm -rf traces.vcd
	@rm -rf results.xml
	@rm -rf sim_build
	@rm -rf __pycache__
