import numpy as np
import struct, cocotb
from cocotb.triggers import ClockCycles, RisingEdge, Timer
from cocotb.clock import Clock


@cocotb.test()
async def bram_async_test(dut, addr_len=256):
    wclk = Clock(dut.wclk, 8, units="ns")
    cocotb.fork(wclk.start())
    rclk = Clock(dut.rclk, 10, units="ns")
    cocotb.fork(rclk.start())
    #init the values
    dut.wen <=0
    dut.waddr <=0
    dut.waddr <=0
    dut.win <=0
    dut.ren <=0
    dut.raddr <=0
    await ClockCycles(dut.rclk, 8)
    data = np.arange(addr_len)
    write = await write_only(dut, data)
    read = await read_only(dut, len(data))
    for i in range(len(read)):
        print(read[i])
    await ClockCycles(dut.wclk, 30) 



async def write_only(dut, data):
    print("write only")
    await RisingEdge(dut.wclk)
    wready = int(dut.wready.value)
    if(wready):
        for i in range(len(data)):
            dut.waddr <= i
            dut.win <= int(data[i])
            dut.wen <=1
            await ClockCycles(dut.wclk, 1)
        dut.wen <=0
        return 1
    else:
        print("No wready!")
        return 0

async def read_only(dut, length):
    dat = []
    await RisingEdge(dut.rclk)
    dut.ren <=1;
    for i in range(length):
        dut.raddr <= int(i)
        await ClockCycles(dut.rclk,1)
        valid = int(dut.rvalid.value)
        if(valid):
            dout = int(dut.rout.value)
            dat.append(dout)
    dut.ren <=0
    dat = np.array(dat)
    return dat





