import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
import random
import numpy as np

###
### Author: Sebastian Jorquera
###

@cocotb.test()
async def ascii2bin_test(dut, iters=32, digits=3):
    ##setup dut
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    
    dut.rst.value =0
    dut.ascii_in.value =0
    dut.din_valid.value =0
    
    await ClockCycles(dut.clk,10)

    ##
    random.seed(16)
    num = '0123456789'
    gold = ''.join(random.choice(num) for i in range(digits*iters))
    din = list(gold.encode('ascii'))
    gold_int = np.zeros(iters)
    for i in range(iters):
        gold_int[i] = int(gold[digits*i:digits*(i+1)])
    cocotb.fork(write_data(dut, din))
    cocotb.fork(reset_sys(dut))
    await read_data(dut, gold_int)


async def write_data(dut, data):
    for i in range(len(data)):
        dut.din_valid.value = 1
        dut.ascii_in.value = int(data[i])
        await ClockCycles(dut.clk,1)
        dut.din_valid.value = 0
        await ClockCycles(dut.clk, random.randint(4,60))

async def reset_sys(dut):
    while(1):
        valid = int(dut.dout_valid.value)
        if(valid):
            dut.rst.value = 1
            await ClockCycles(dut.clk, 1)
            dut.rst.value = 0
        await ClockCycles(dut.clk,1)

async def read_data(dut, gold):
    count =0
    while(count<len(gold)):
        valid = int(dut.dout_valid.value)
        if(valid):
            dout = int(dut.dout.value)
            print("rtl: %i \t gold:%i" %(dout, gold[count]))
            assert (dout==gold[count])
            count +=1
        await ClockCycles(dut.clk, 1)
        

    
