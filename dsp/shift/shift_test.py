import cocotb
import pytest, os
import numpy as np
import cocotb_test.simulator
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def shift_test(dut):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    
    dut.din.value =0
    await ClockCycles(dut.clk, 10)
    
    din_data = np.arange(128)*2
    for dat in din_data:
        dut.din.value = -int(dat)
        await ClockCycles(dut.clk, 1)


