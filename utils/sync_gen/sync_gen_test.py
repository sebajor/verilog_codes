import cocotb
import numpy as np
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock

@cocotb.test()
async def sync_gen_test(dut):
    sync_in_period = 64
    sync_out_period = 128*4
    iters = 20
    
    clk = Clock(dut.clk, 10, 'ns')
    cocotb.fork(clk.start())
    dut.rst <= 0;
    dut.sync_period <= sync_out_period
    dut.sync_in <= 0;
    dut.val <= 0
    await ClockCycles(dut.clk,3)

    for i in range(iters):
        for j in range(sync_in_period-1):
            dut.val <= int(j)
            dut.sync_in <= 0;
            await ClockCycles(dut.clk,1)
        dut.sync_in <= 1;
        dut.val <= sync_in_period-1
        await ClockCycles(dut.clk, 1)

