import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
import numpy as np

@cocotb.test()
async def autoscale_test(dut, iters=128, din_width=32):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    dut.din_valid <= 0
    dut.din1 <=0; dut.din2 <= 0
    await ClockCycles(dut.clk, 3)
    np.random.seed(10)
    for i in range(iters):
        dut.din_valid <= 1
        dut.din1 <= np.random.randint(0, 2**27-1)
        dut.din2 <= np.random.randint(0, 2**10-1)
        await ClockCycles(dut.clk, 1)

    
