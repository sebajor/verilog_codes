import numpy as np
import cocotb
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock


@cocotb.test()
async def galois_lfsr_test(dut, iters=64):
    cocotb.fork(Clock(dut.clk, 10, units='ns').start())
    dut.seed <= 1
    dut.en <=0
    dut.rst <=1
    await ClockCycles(dut.clk,1)
    dut.rst <=0
    dut.en <=1
    for i in range(iters):
        await ClockCycles(dut.clk,1)
        out = dut.dout.value
        
        print("iter:"+str(i)+"\t"+str(out))
