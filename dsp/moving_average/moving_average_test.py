import numpy as np
import cocotb
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.clock import Clock
import sys
sys.path.append('../../cocotb_python')
from two_comp import two_comp_pack, two_comp_unpack

def moving_average(data, win_len):
    ret = np.cumsum(data, dtype=float)
    ret[win_len:] = ret[win_len:] - ret[:-win_len]
    return ret[win_len-1:]/win_len

@cocotb.test()
async def moving_average_test(dut, iters=1024, win_len=16, 
        din_width=32, din_pt=31, thresh=0.1):
    back = 16
    burst_len = 1
    cont = None


    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())

    np.random.seed(12)
    #setup the dut
    dut.din.value =0
    dut.din_valid.value =0
    dut.rst.value =0
    await ClockCycles(dut.clk, 5)
    ##
    data = np.random.random(iters)
    data_b = two_comp_pack(data, din_width, din_pt)
    
    gold = moving_average(np.hstack([np.zeros(win_len-1),data]), win_len)
    cocotb.fork(read_data(dut, gold, din_width, din_pt, thresh))
    await write_data(dut, data_b, back, burst_len, cont=cont)
    

async def write_data(dut, data, back, burst_len, cont=None):
    if(cont is not None):
        for dat in data:
            dut.din.value = int(dat)
            dut.din_valid.value =1
            await ClockCycles(dut.clk, 1)
    else:
        for i in range(len(data)):
            dut.din.value = int(data[i])
            dut.din_valid.value = 1
            await ClockCycles(dut.clk, 1)
            if((i%burst_len == 0) and (i!=0)):
                dut.din_valid.value =0
                await ClockCycles(dut.clk, back)

async def read_data(dut, gold, dout_width, dout_pt, thresh):
    count =0
    while(count < len(gold)):
        valid = int(dut.dout_valid.value)
        if(valid):
            dout = int(dut.dout.value)
            dout = two_comp_unpack(np.array(dout), dout_width, dout_pt)
            print("gold: %.2f \t rtl: %.2f" %(gold[count], dout))
            assert (np.abs(gold[count]-dout)<thresh), "Error"
            count +=1
        await ClockCycles(dut.clk,1)
