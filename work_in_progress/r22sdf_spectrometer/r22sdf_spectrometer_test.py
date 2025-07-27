import numpy as np
import cocotb
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
import cocotb_test.simulator
import pytest
import itertools
import sys, os
cocotb_path = os.path.abspath('../../../../cocotb_python/')
sys.path.append(cocotb_path)
from two_comp import two_comp_pack, two_comp_unpack
import subprocess
from cocotbext.axi import AxiLiteBus, AxiLiteMaster, AxiLiteRam

###
### author: sebastian jorquera
###
AXI_PERIOD = 10
FPGA_PERIOD = 8

def setup_dut(dut):
    cocotb.start_soon(Clock(dut.axi_clock, AXI_PERIOD, units='ns').start())
    fpga_clk = Clock(dut.clk, FPGA_PERIOD, units='ns')
    cocotb.start_soon(fpga_clk.start())

    dut.rst.value= 1
    dut.bram_we.value=0
    dut.bram_addr.value=0
    dut.bram_din.value= 0
    dut.s_axil_araddr.value= 0
    dut.s_axil_arprot.value= 0
    dut.s_axil_arvalid.value= 0
    dut.s_axil_rready.value= 0
    axil_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_axil"), dut.axi_clock, dut.rst)
    dut.s_axil_araddr.value= 0
    dut.s_axil_arprot.value= 0
    dut.s_axil_awaddr.value=0
    dut.s_axil_awprot.value=0
    dut.s_axil_wdata.value=0
    dut.s_axil_wstrb.value=0




@cocotb.test()
async def r22sdf_spectrometer_test(dut, thresh=1e-4, acc_len=10):
    fft_size = int(dut.FFT_SIZE)
    din_width = int(dut.DIN_WIDTH)
    din_point = int(dut.DIN_POINT)
    iters = 10
    ##
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    dut.rst.value =0
    dut.din_valid.value = 0
    dut.din_re.value = 0
    dut.din_im.value = 0
    await ClockCycles(dut.clk, 3)
    np.random.seed(123)



