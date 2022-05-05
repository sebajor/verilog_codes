import numpy as np
import cocotb
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock

###
### Author: Sebastian Jorquera
###

@cocotb.test()
async def acc_control_test(dut, acc_len=5, channels=7):
    #setup dut
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    
    dut.rst.value =0
    dut.acc_len.value = acc_len
    dut.sync_in.value =0
    
    await ClockCycles(dut.clk, 4)
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 5)
    for i in range(2*acc_len+5):
        dut.sync_in.value = 1;
        await ClockCycles(dut.clk,1)
        dut.sync_in.value = 0
        await ClockCycles(dut.clk, 2**channels-1)

    await ClockCycles(dut.clk, 10)
