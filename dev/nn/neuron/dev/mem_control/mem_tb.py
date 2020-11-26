import cocotb, struct
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge,FallingEdge, ClockCycles
from cocotb.binary import BinaryValue
import numpy as np


@cocotb.test()
async def mem_tb(dut):
    clock = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clock.start())
    dut.rst <= 1
    dut.valid <=0
    await ClockCycles(dut.clk, 2)
    dut.rst <= 0
    await ClockCycles(dut.clk, 2)
    dut.valid <= 1
    await ClockCycles(dut.clk, 10)
    dut.rst <=1
    await ClockCycles(dut.clk, 1)
    dut.rst <= 0
    await ClockCycles(dut.clk, 259)

   

