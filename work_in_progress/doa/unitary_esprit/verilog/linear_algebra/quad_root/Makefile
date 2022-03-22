dut=quad_root
SIM=icarus

WAVES ?= 0

TOPLEVEL_LANG = verilog
VERILOG_SOURCES = $(shell pwd)/$(dut)_tb.v
TOPLEVEL = $(dut)_tb
MODULE = $(dut)_test 

#weight rom file
SQRT_IN_WIDTH = 12
SQRT_IN_POINT = 7
SQRT_OUT_WIDTH = 16
SQRT_OUT_POINT = 13
FILENAME = "sqrt.mem"

ifeq ($(WAVES), 1)
	VERILOG_SOURCES += iverilog_dump.v
	PLUSARGS += -fst
	COMPILE_ARGS += -s iverilog_dump
endif


include $(shell cocotb-config --makefiles)/Makefile.sim

gen_rom:
	python2 sqrt_gen.py --din_width $(SQRT_IN_WIDTH) --din_pt $(SQRT_IN_POINT)\
	   					--dout_width $(SQRT_OUT_WIDTH) --dout_pt $(SQRT_OUT_POINT)\
					   	--filename sqrt.mem --plot 1

iverilog_dump.v:
	echo 'module iverilog_dump();' > $@
	echo 'initial begin' >> $@
	echo '    $$dumpfile("traces.fst");' >> $@
	echo '    $$dumpvars();' >> $@
	echo 'end' >> $@
	echo 'endmodule' >> $@

clean::
	@rm -rf traces.vcd traces.fst
	@rm -rf results.xml
	@rm -rf sim_build
	@rm -rf __pycache__
	@rm -rf *.del 
	@rm -rf iverilog_dump.v
