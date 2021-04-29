dut=quad_root
SIM=icarus
TOPLEVEL_LANG = verilog
VERILOG_SOURCES = $(shell pwd)/$(dut)_tb.v
TOPLEVEL = $(dut)_tb
MODULE = $(dut)_test 

include $(shell cocotb-config --makefiles)/Makefile.sim
