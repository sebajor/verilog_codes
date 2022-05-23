import cocotb, sys
import numpy as np
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.queue import Queue
from cocotb.handle import SimHandleBase
sys.path.append('../../../../../cocotb_python/')
from two_comp import two_comp_pack, two_comp_unpack
import itertools

###
### Author: Sebastian Jorquera
###

@cocotb.test()
async def arctan2_test(dut, din_width=16, dout_width=16, iters=255, thresh=10**-7):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    din_pt = din_width-1; dout_pt=dout_width-1
    #setup the dut
    dut.x.value =0
    dut.y.value =0
    dut.din_valid.value =0
    await ClockCycles(dut.clk, 3)
    ##  
    np.random.seed(10)
    din1 = np.random.random(iters)-0.5
    din2 = np.random.random(iters)-0.5
    #write data
    cocotb.fork(write_data(dut, din1, din2, din_width, dout_width, iters, thresh))
    await read_data(dut, din1, din2, dout_width, thresh)

async def read_data(dut, din1, din2, dout_width, thresh):
    gold = np.arctan2(din2, din1)/np.pi
    count =0
    for i in range(25*len(din1)):
        await ClockCycles(dut.clk,1)
        valid = int(dut.dout_valid.value)
        if(valid==1):
            out = np.array(int(dut.dout.value))
            out = two_comp_unpack(out, dout_width, dout_width-1)
            assert ((np.abs(gold[count]-out)<thresh)), 'Error!'
            print('gold: %.4f \t rtl: %.4f' %(gold[count], out))
            count += 1


async def write_data(dut, din1, din2, din_width, dout_width, iters, thresh):
    count = 0
    x = two_comp_pack(din1, din_width, din_width-1)
    y = two_comp_pack(din2, din_width, din_width-1)
    dut.x.value = int(x[0])
    dut.y.value = int(y[0])
    dut.din_valid.value =1
    await ClockCycles(dut.clk,1)
    dut.din_valid.value = 0
    for i in range(1,len(x)):
        await RisingEdge(dut.sys_ready)
        await ClockCycles(dut.clk, np.random.randint(8))
        dut.x.value = int(x[i])
        dut.y.value = int(y[i])
        dut.din_valid.value =1;
        await ClockCycles(dut.clk, 1)
        dut.din_valid.value =0;
