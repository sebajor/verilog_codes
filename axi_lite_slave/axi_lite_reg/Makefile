TOPLEVEL_LANG = verilog
PWD=$(shell pwd)
SIM=icarus
VERILOG_SOURCES = s_axi_lite_reg.v
VERILOG_SOURCES += tb_axi_lite_slave.v

TOPLEVEL = tb_axi_lite_slave
GPI_IMPL :=vpi

export TOPLEVEL_LANG
MODULE = test_axi_lite_slave

include $(shell cocotb-config --makefiles)/Makefile.sim
