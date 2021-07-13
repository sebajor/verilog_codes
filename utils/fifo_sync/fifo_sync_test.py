import numpy as np
import struct, cocotb
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
from cocotb.binary import BinaryValue

@cocotb.test()
async def fifo_sync_test(dut, din_width=16, naddr=16):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    np.random.seed(10)

    dut.rst <=1; 
    dut.wdata <=0;
    dut.w_valid<=0
    dut.read_req <=0
    
    await ClockCycles(dut.clk, 1)
    dut.rst <=0;
    await ClockCycles(dut.clk,1)
    
    data = np.arange(128)+1
    #test = await write_read(dut,data, w_period=5)
    test = await write_read2(dut,data, w_period=5)
    print(test)

    
async def write_read(dut, data, iters=128,w_period=2, r_period=3):
    length = len(data)
    w_pt = 0
    out_vals = []
    for i in range(iters):
        if(i%w_period==0):
            dut.wdata <= int(data[w_pt])
            dut.w_valid <=1;
            w_pt = w_pt+1
        else:
            dut.w_valid <=0;
        if(i%r_period==0):
            dut.read_req <= 1;
        else:
            dut.read_req <=0
        await ClockCycles(dut.clk, 1)
        valid = int(dut.r_valid.value)
        if(valid):
            out = int(dut.rdata.value)
            out_vals.append(out)
    return out_vals




async def write_read2(dut, data, iters=128,w_period=2, r_period=3):
    """attempt to read only when the fifo is not empty
    """
    length = len(data)
    w_pt = 0
    out_vals = []
    empty =1
    for i in range(iters):
        if(i%w_period==0):
            dut.wdata <= int(data[w_pt])
            dut.w_valid <=1;
            w_pt = w_pt+1
        else:
            dut.w_valid <=0;
        if(~empty):
            dut.read_req <= 1;
        else:
            dut.read_req <=0
        await ClockCycles(dut.clk, 1)
        valid = int(dut.r_valid.value)
        empty = int(dut.empty.value)
        print(empty)
        if(valid):
            out = int(dut.rdata.value)
            out_vals.append(out)
    return out_vals

