import cocotb, struct
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge,FallingEdge, ClockCycles
from cocotb.binary import BinaryValue
import numpy as np



@cocotb.test()
async def acc_tb(dut):
    clock = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clock.start())
    bin_pt = 12
    out_width = 32
    out_pt = 18
    do = BinaryValue()
    test_data = np.arange(32)*0.1
    din = test_data*2**bin_pt
    dut.rst <= 0
    dut.last <= 0
    out = await test2(dut, din,out_width, out_pt)
    print("Coroutine result: "+str(out)+"\t ideal: "+str(np.sum(test_data)))
    np.random.seed(10)
    test_data = np.random.rand(40)*-1
    din = test_data*2**bin_pt
    out = await test2(dut, din,out_width, out_pt)
    print("Coroutine result: "+str(out)+"\t ideal: "+str(np.sum(test_data)))
    test_data = np.ones(1130)*-7.3#np.arange(12)*0.1
    din = test_data*2**bin_pt
    out = await test2(dut, din,out_width, out_pt)
    print("Coroutine result: "+str(out)+"\t ideal: "+str(np.sum(test_data)))


async def test(dut, data, out_width, out_pt):
    for i in range(len(data)):
        dut.din <= int(data[i]);dut.en <= 1
        await ClockCycles(dut.clk, 1) 
    dut.en <= 0;
    dut.last <=1
    await ClockCycles(dut.clk, 1)
    dut.last <= 0
    out_val  = int(dut.dout)
    #await ClockCycles(dut.clk, 1)
    do = BinaryValue()
    if(out_val>2**(out_width-1)-1):
        ##negative value
        do.integer = out_val
        out = struct.unpack('>i', do.buff)[0]/2**out_pt
    else:
        out = out_val/2**out_pt
    return out

async def test2(dut, data, out_width, out_pt):
    for i in range(len(data)-1):
        dut.din <= int(data[i]);dut.en <= 1
        await ClockCycles(dut.clk, 1)
    dut.din <= int(data[i+1])
    dut.last <=1
    await ClockCycles(dut.clk, 1)
    dut.en <= 0
    dut.last <= 0
    await ClockCycles(dut.clk, 1)
    out_val  = int(dut.dout)
    #await ClockCycles(dut.clk, 1)
    do = BinaryValue()
    if(out_val>2**(out_width-1)-1):
        ##negative value
        do.integer = out_val
        out = struct.unpack('>i', do.buff)[0]/2**out_pt
    else:
        out = out_val/2**out_pt
    return out




