dut=image_convolution
SIM=icarus

WAVES ?= 0

TOPLEVEL_LANG = verilog
VERILOG_SOURCES = $(shell pwd)/$(dut)_tb.v
TOPLEVEL = $(dut)_tb
MODULE = $(dut)_test 

#weight rom file
WEIGHT_WIDTH= 8
WEIGHT_POINT= 5
WEIGHT_FOLDER_IN = "weight/"
WEIGHT_FOLDER_OUT = "weight/"

ifeq ($(WAVES), 1)
	VERILOG_SOURCES += iverilog_dump.v
	PLUSARGS += -fst
	COMPILE_ARGS += -s iverilog_dump
endif


include $(shell cocotb-config --makefiles)/Makefile.sim

quantize_weight:
	python2 quantize_weight.py --width $(WEIGHT_WIDTH) --pt $(WEIGHT_POINT) \
				--folder_in $(WEIGHT_FOLDER_IN) --folder_out $(WEIGHT_FOLDER_OUT)


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
