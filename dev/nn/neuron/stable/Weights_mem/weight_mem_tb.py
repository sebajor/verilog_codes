import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, ClockCycles


@cocotb.test()
async def test_weight(dut):
    clock = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clock.start())
    for i in range(128):
        dut.wen <= 1
        dut.wadd <= i
        dut.win <= i
        await FallingEdge(dut.clk)
    dut.wen <=0 
    dut.radd <= 0
    dut.ren <=1
    await ClockCycles(dut.clk, 1)
    for i in range(1,128):
        dut.ren <= 1
        dut.radd <= i
        #await FallingEdge(dut.clk)
        await ClockCycles(dut.clk, 1)
        #await ClockCycles(dut.clk, 1)
        assert dut.wout.value ==(i-1), "Error in {}".format(i-1)
