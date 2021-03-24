import os
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles
from cocotb.drivers.amba import AXI4LiteMaster
from cocotb.drivers.amba import AXIProtocolError


CLK_PERIOD = 10


def setup_dut(dut):
    cocotb.fork(Clock(dut.S_AXI_ACLK, CLK_PERIOD, units='ns').start())


@cocotb.test()
async def write_read(dut):
    """Write the 32 addresses and read them
    """
    dut.S_AXI_ARESETn <= 1
    axim = AXI4LiteMaster(dut, "S_AXI", dut.S_AXI_ACLK)
    setup_dut(dut)
    await Timer(CLK_PERIOD*10, units='ns')
    
    print("start writing axi registers")
    for i in range(32):
        dut.win <= i
        dut.waddr <= i
        dut.w_en <= 1
        #await axim.write(4*i, i)
        await Timer(CLK_PERIOD, units='ns')
    print("finish writing the registers")
    dut.win <= 2
    dut.waddr <=2
    print("start reading axi registers")
    for i in range(32):
        value = await axim.read(4*i)
        assert value == i, ("Register at addr %i is 0x%08X" %(i, int(value)))


