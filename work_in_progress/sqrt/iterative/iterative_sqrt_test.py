import numpy as np
import cocotb
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge
from cocotb.clock import Clock

###
### Author: Sebastian Jorquera
###

@cocotb.test()
async def iterative_sqrt_test(dut, din_width=10, din_pt=6, 
        thresh=0.04):
    dout_width = din_width
    dout_pt = din_pt

    clock = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clock.start())
    dut.din.value = 0
    dut.din_valid.value =0
    await ClockCycles(dut.clk, 5)

    din = np.arange(2**din_width)

    gold= np.sqrt(din/2.**din_pt)

    cocotb.fork(read_data(dut, gold, dout_pt,thresh))
    await write_data(dut, din)


async def write_data(dut,data):
    count =0
    prev=0
    while(count<len(data)):
        busy = int(dut.busy.value)
        dut.din_valid.value = 1
        #if( (not busy) and (not prev)):
        if(not busy):
            prev = 1    ##otherwise it tries to write two sucesive cycles
            dut.din.value = int(data[count])
            #dut.din_valid.value = 1
            count +=1
        else:
            prev =0
            #dut.din_valid.value =0
        await ClockCycles(dut.clk,1)

async def read_data(dut, gold, dout_pt, thresh):
    count =0
    while(count<len(gold)):
        valid = int(dut.dout_valid.value)
        if(valid):
            dout = int(dut.dout.value)/2.**dout_pt
            print("gold:%.4f \t rtl:%.4f" %(gold[count], dout))
            assert (np.abs(dout-gold[count])<thresh), "Error!"
            count +=1
        await ClockCycles(dut.clk,1)

