import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, ClockCycles


@cocotb.test()
async def bram_test(dut):
    clock = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clock.start())
    dut.ren.value = 0
    dut.radd.value =0
    await ClockCycles(dut.clk, 1)
    for i in range(128):
        dut.wen.value = 1
        dut.wadd.value = i
        dut.win.value = i
        await ClockCycles(dut.clk,1)
    dut.wen.value =0 
    dut.radd.value = 0
    dut.ren.value =1
    await ClockCycles(dut.clk, 1)
    for i in range(1,128):
        dut.ren.value = 1
        dut.radd.value = i
        #await FallingEdge(dut.clk)
        await ClockCycles(dut.clk, 1)
        #await ClockCycles(dut.clk, 1)
        assert dut.wout.value ==(i-1), "Error in {}".format(i-1)
