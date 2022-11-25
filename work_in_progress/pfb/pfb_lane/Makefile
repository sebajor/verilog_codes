dut=pfb_real_lane
SIM=icarus

WAVES ?= 0

TOPLEVEL_LANG = verilog
VERILOG_SOURCES = $(shell pwd)/$(dut)_tb.v
TOPLEVEL = $(dut)_tb
MODULE = $(dut)_test 

#coeff generation
COEFF_FOLDER = pfb_coeff
PFB_SIZE = 32
TAPS = 5
LANES = 4
DATAWIDTH = 18
DATAPOINT = 17
WINDOW = hamming


ifeq ($(WAVES), 1)
	VERILOG_SOURCES += iverilog_dump.v
	PLUSARGS += -fst
	COMPILE_ARGS += -s iverilog_dump
endif


include $(shell cocotb-config --makefiles)/Makefile.sim

gen_coeffs:
	python3 gen_pfb_coeffs.py --folder $(COEFF_FOLDER) \
		--pfb_size $(PFB_SIZE) \
		--taps $(TAPS) \
		--lanes $(LANES) \
		--bitwidth $(DATAWIDTH) \
		--bitpoint $(DATAPOINT) \
		--window $(WINDOW) \
		--debug

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
	@rm -rf *.del *.npy *.npz
	@rm -rf iverilog_dump.v

