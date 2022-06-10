dut=spiral_fft
SIM=icarus

WAVES ?= 0

TOPLEVEL_LANG = verilog
VERILOG_SOURCES = $(shell pwd)/$(dut).v
#TOPLEVEL = $(dut)_tb
#MODULE = $(dut)_test 

#weight rom file

ifeq ($(WAVES), 1)
	VERILOG_SOURCES += iverilog_dump.v
	PLUSARGS += -fst
	COMPILE_ARGS += -s iverilog_dump
endif

all:
	iverilog -o $(dut)_sim $(dut).v 
	vvp $(dut)_sim -fst

iverilog_dump.v:
	echo 'module iverilog_dump();' > $@
	echo 'initial begin' >> $@
	echo '    $$dumpfile("traces.fst");' >> $@
	echo '    $$dumpvars();' >> $@
	echo 'end' >> $@
	echo 'endmodule' >> $@

clean::
	@rm -rf *_sim
	@rm -rf traces.vcd traces.fst
	@rm -rf results.xml
	@rm -rf sim_build
	@rm -rf __pycache__
	@rm -rf *.del
	@rm -rf iverilog_dump.v
