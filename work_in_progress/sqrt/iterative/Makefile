dut=iterative_sqrt
SIM=icarus

WAVES ?= 0

TOPLEVEL_LANG = verilog
VERILOG_SOURCES = $(shell pwd)/$(dut)_tb.v
TOPLEVEL = $(dut)_tb
MODULE = $(dut)_test 

FPGA_PART = xc7k325t-ffg676-2

#sigmoid rom file
DIN_WIDTH= 16
DIN_POINT= 10
DOUT_WIDTH= 10
DOUT_POINT= 6

ifeq ($(WAVES), 1)
	VERILOG_SOURCES += iverilog_dump.v
	PLUSARGS += -fst
	COMPILE_ARGS += -s iverilog_dump
endif


include $(shell cocotb-config --makefiles)/Makefile.sim


gen_rom:
	python2 sqrt_gen.py --din_width $(DIN_WIDTH) --din_pt $(DIN_POINT)\
	   					--dout_width $(DOUT_WIDTH) --dout_pt $(DOUT_POINT)\
					   	--filename sqrt.mem --plot 1

synth:
	rm -rf synthesis.tcl
	echo "create_project -force -part $(FPGA_PART) synth_test" > synthesis.tcl
	echo "add_files -fileset sources_1 $(VERILOG_SOURCES)" >> synthesis.tcl
	echo "reset_run synth_1" >> synthesis.tcl
	echo "launch_runs synth_1" >> synthesis.tcl
	echo "wait_on_run synth_1" >> synthesis.tcl
	echo "exit" >> synthesis.tcl
	vivado -nojournal -nolog -mode batch -source synthesis.tcl


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
	@rm -rf synthesis.tcl
	@rm -rf *.cache *.hw *.ip_user_files *.runs *.xpr *.sim
	@rm -rf .Xil



