dut=msdft
SIM=icarus

WAVES ?= 0

TOPLEVEL_LANG = verilog
VERILOG_SOURCES = $(shell pwd)/$(dut)_tb.v
TOPLEVEL = $(dut)_tb
MODULE = $(dut)_test

TWIDD_WIDTH = 16
TWIDD_POINT = 14
TWIDD_NUM = 55
DFT_SIZE = 128
TWIDD_FILE = twidd_init.bin


ifeq ($(WAVES), 1)
	VERILOG_SOURCES += iverilog_dump.v
	COMPILE_ARGS += -s iverilog_dump
endif

include $(shell cocotb-config --makefiles)/Makefile.sim

twidd_gen:
	python ../twidd_gen.py	--din_width $(TWIDD_WIDTH) --din_pt $(TWIDD_POINT) \
		--twidd_num $(TWIDD_NUM) --dft_size $(DFT_SIZE) -f $(TWIDD_FILE) 

iverilog_dump.v:
	echo 'module iverilog_dump();' > $@
	echo 'initial begin' >> $@
	echo '    $$dumpfile("traces.vcd");' >> $@
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
