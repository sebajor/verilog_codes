import cocotb, sys
import numpy as np
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
sys.path.append('../../../../../cocotb_python/')
from two_comp import two_comp_pack, two_comp_unpack

@cocotb.test()
async def arctan2_multiplexed_test(dut, din_width=16, iters=256, parallel=4,
        burst_len=10, rest=100, thresh=10**-2):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    #setup the dut
    dut.rst.value = 0;
    dut.x0.value =0;    dut.y0.value =0
    dut.x1.value =0;    dut.y1.value =0
    dut.x2.value =0;    dut.y2.value =0
    dut.x3.value =0;    dut.y3.value =0
    dut.din_valid.value =0
    await ClockCycles(dut.clk, 3)

    ##
    np.random.seed(10)
    din1 = np.random.random([iters,parallel])-0.5
    din2 = np.random.random([iters,parallel])-0.5

    din1_b = two_comp_pack(din1.flatten(), din_width, din_width-1).reshape(din1.shape)
    din2_b = two_comp_pack(din2.flatten(), din_width, din_width-1).reshape(din2.shape)

    gold = np.arctan2(din2, din1)/np.pi
    
    cocotb.fork(write_data(dut, din1_b, din2_b, burst_len, rest))
    await read_data(dut, din_width, gold.flatten(), thresh)


async def write_data(dut, din1, din2,burst_len, rest):
    for i in range(din1.shape[0]):
        dut.x0.value = int(din1[i,0]) 
        dut.x1.value = int(din1[i,1]) 
        dut.x2.value = int(din1[i,2]) 
        dut.x3.value = int(din1[i,3]) 
        dut.y0.value = int(din2[i,0]) 
        dut.y1.value = int(din2[i,1]) 
        dut.y2.value = int(din2[i,2]) 
        dut.y3.value = int(din2[i,3])
        dut.din_valid.value = 1
        await ClockCycles(dut.clk,1)
        if((i%burst_len==0) and (i!=0)):
            dut.din_valid.value = 0
            await ClockCycles(dut.clk, rest)

async def read_data(dut, dout_width, gold, thresh):
    count =0
    while(count< len(gold)):
        valid = dut.dout_valid.value
        if(valid):
            out = np.array(int(dut.dout.value))
            out = two_comp_unpack(out, dout_width, dout_width-1)
            print('gold: %.4f \t rtl: %.4f' %(gold[count], out))
            assert ((np.abs(gold[count]-out)<thresh)), 'Error!'
            count +=1
        await ClockCycles(dut.clk, 1)








