
TOPLEVEL_LANG ?= verilog

ifneq ($(TOPLEVEL_LANG),verilog)
all:
	@echo "Skipping; this example does not support VHDL at the top-level"
clean::

else

PWD=$(shell pwd)
TOPDIR=$(PWD)
PYTHONPATH := ./model:$(PYTHONPATH)

export PYTHONPATH

SIM ?= icarus

#not sure if only icarus include is by -I ...
ifeq ($(SIM),icarus)
COMPILE_ARGS+=-I$(TOPDIR)
else
COMPILE_ARGS+=+incdir+$(TOPDIR)
endif

#DUT
VERILOG_SOURCES = zipcpu_demo.v
#Test Bench
VERILOG_SOURCES += tb_axi_lite_slave.v

TOPLEVEL = tb_axi_lite_slave

GPI_IMPL := vpi

export TOPLEVEL_LANG
MODULE=test_axi_lite_slave

include $(shell cocotb-config --makefiles)/Makefile.sim

endif
