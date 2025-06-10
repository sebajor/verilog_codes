import numpy as np
import cocotb
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
import cocotb_test.simulator
import pytest

###
###     Author: Sebastian Jorquera
###

@cocotb.test()
async def feedback_delay_line_test(dut, din_width=16,fifo_depth=32, iters=128):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    dut.rst.value =0
    
    np.random.seed(123)
    #data = np.random.randint(0, 2**din_width, size=iters)
    data = np.arange(iters)
    cocotb.start_soon(write_data(dut, data))
    await read_data(dut, data, fifo_depth)

async def write_data(dut, data):
    for dat in data:
        dut.din.value = int(dat)
        dut.din_valid.value = 1
        await ClockCycles(dut.clk, 1)

async def read_data(dut, gold_data, fifo_depth):
    count = 0
    while(count<len(gold_data)+fifo_depth):
        if(dut.dout_valid.value):
            out = int(dut.dout.value)
            delay_out = int(dut.delay_data.value)
            assert (out==delay_out)
            count +=1
        await ClockCycles(dut.clk, 1)

    
