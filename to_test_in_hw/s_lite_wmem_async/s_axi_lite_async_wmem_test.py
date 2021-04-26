import os
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ClockCycles
from cocotb.drivers.amba import AXI4LiteMaster
from cocotb.drivers.amba import AXIProtocolError


CLK_PERIOD = 8


def setup_dut(dut):
    cocotb.fork(Clock(dut.S_AXI_ACLK, CLK_PERIOD, units='ns').start())
    rclk = Clock(dut.rclk, 10, units='ns')
    cocotb.fork(rclk.start())
    dut.ren <=0
    dut.raddr <=0


@cocotb.test()
async def write_read(dut):
    """Write the 32 addresses and read them
    """
    dut.S_AXI_ARESETn <= 1
    axim = AXI4LiteMaster(dut, "S_AXI", dut.S_AXI_ACLK)
    setup_dut(dut)
    await Timer(CLK_PERIOD*10, units='ns')
    print("start writing axi registers")
    await RisingEdge(dut.S_AXI_ACLK)
    for i in range(32):
        await axim.write(4*i, i)
        await Timer(CLK_PERIOD*2, units='ns')
    print("finish writing the registers")
    
    print("start reading axi registers")
    await RisingEdge(dut.rclk)
    for i in range(32):
        dut.ren <=1;
        dut.raddr <= int(i)
        await ClockCycles(dut.rclk, 1)
        valid = int(dut.rvalid.value)
        if(valid):
            out = int(dut.rout.value)
            print("iter: %i val: %i"%(i, out))

