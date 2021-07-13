import numpy as np
import cocotb, random
from cocotb.clock import Clock
from cocotb.binary import BinaryValue
from cocotb.triggers import ClockCycles

@cocotb.test()
async def skid_buffer_test(dut, iters=128):
    din_width = 32
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    np.random.seed(20)
    ##initialize 
    dut.rst <= 1
    dut.dout_ready <=0
    dut.din <= 0
    dut.din_valid <=0
    await ClockCycles(dut.clk, 2)
    dut.rst <= 0
    await ClockCycles(dut.clk, 1)
    #cont = await continous_stream(dut, iters)
    back = await backpreassure(dut, iters)


async def continous_stream(dut, iters):
    count = 0
    dut.dout_ready <= 1;
    await ClockCycles(dut.clk, 1)
    for i in range(iters):
        dut.din <= int(i)
        dut.din_valid <= 1
        await ClockCycles(dut.clk,1)
        out_val = int(dut.dout_valid.value)
        if(out_val):
            dout = int(dut.dout.value)
            assert (dout==count), "fail in {}".format(i)
            count = count +1
    dut.din_valid <= 0
    await ClockCycles(dut.clk,1)
    return 1
            
async def backpreassure(dut, iters, num_stalled=10):
    count =0
    dut.dout_ready <= 1
    stall = random.randint(1,int(iters/num_stalled))
    stall_time = random.randint(1, 10)
    i = iters
    for i in range(iters):
        if(stall==0):
            dut.din <= int(i)
            dut.dout_ready <=0
            dut.din_valid <=1
            await ClockCycles(dut.clk, stall_time)
            dut.dout_ready <= 1
            stall = random.randint(1,int(iters/num_stalled))
            stall_time = random.randint(1, 10)
            pass
        stall = stall -1
        dut.din <= int(i)
        dut.din_valid <= 1
        await ClockCycles(dut.clk, 1)
        out_val = int(dut.dout_valid.value)
        if(out_val):
            dout = int(dut.dout.value)
            assert (dout==count), "fail in {}".format(i)
            count = count +1
        
            





