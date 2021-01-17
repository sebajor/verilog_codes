import os
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer
from cocotb.drivers.amba import AXI4LiteMaster
from cocotb.drivers.amba import AXIProtocolError


CLK_PERIOD = 10


def setup_dut(dut):
    cocotb.fork(Clock(dut.clk, CLK_PERIOD, units='ns').start())


@cocotb.test()
async def write_read(dut):
    """Write the 32 addresses and read them
    """
    dut.rst <= 1
    axim = AXI4LiteMaster(dut, "AXIML", dut.clk)
    setup_dut(dut)
    await Timer(CLK_PERIOD*10, units='ns')
    
    print("start writing axi registers")
    for i in range(32):
        await axim.write(4*i, i)
        await Timer(CLK_PERIOD*2, units='ns')
    print("finish writing the registers")
 
    print("start reading axi registers")
    for i in range(32):
        value = await axim.read(4*i)
        assert value == i, ("Register at addr %i is 0x%08X" %(i, int(value)))


