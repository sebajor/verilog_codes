import numpy as np
import cocotb
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock

###
###     Author: Sebastian Jorquera
###

@cocotb.test()
async def axis_fifo_sync_test(dut, din_width=16, iters=128, w_cont=1,r_cont=0):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    dut.rst.value =0
    dut.write_tdata.value =0
    dut.write_tvalid.value =0
    dut.read_tready.value = 0
    await ClockCycles(dut.clk, 3)

    np.random.seed(230)
    #gold = np.random.randint(0, 2**16, size=iters)
    gold = np.arange(iters)
    cocotb.fork(write_data(dut, gold, w_cont))
    await read_data(dut, gold, r_cont)
    
async def write_data(dut, gold, w_cont):
    index =0;
    dut.write_tvalid.value = 1
    ##we are going to force the first one
    ready = 1
    valid = 1
    while (index<len(gold)):
        dut.write_tdata.value = int(gold[index])
        if(ready and valid):
            index +=1
        await ClockCycles(dut.clk, 1)
        ready = int(dut.write_tready.value)
        valid = int(dut.write_tvalid.value)
        if(not w_cont):
            dut.write_tvalid.value = int(np.random.randint(2))

async def read_data(dut, gold, r_cont ):
    count =0;
    dut.read_tready.value = 1
    while(count < len(gold)):
        valid = int(dut.read_tvalid.value)
        ready = int(dut.read_tready.value)
        if(valid and ready):
            out = int(dut.read_tdata.value)
            print("gold: %i \t rtl: %i" %(gold[count], out))
            assert (out == gold[count])
            count +=1
        await ClockCycles(dut.clk,1)
        if(not r_cont):
            dut.read_tready.value = int(np.random.randint(2))
