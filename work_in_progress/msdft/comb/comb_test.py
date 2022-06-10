import numpy as np
import cocotb, sys
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.clock import Clock
sys.path.append('../../../cocotb_python')
from two_comp import two_comp_pack, two_comp_unpack

def comb_gold(data, dly_line):
    out = np.zeros(len(data))
    for i in range(len(data)):
        if(i<dly_line):
            out[i] = data[i]
        else:
            out[i] = data[i]-data[i-dly_line]
    return out

    

@cocotb.test()
async def comb_test(dut, iters=128, win_len=8, din_width=16, din_pt=15,
        dout_width=17, thresh=0.01):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    np.random.seed(10)
    dat = (np.random.random(iters)-0.5)*0.9
    dut.delay_line <= (win_len-1)
    gold_data = comb_gold(dat, win_len)
    bin_data = two_comp_pack(dat, din_width, din_pt)
    cocotb.fork(read_data(dut, gold_data, dout_width, din_pt, thresh))
    #await continous_write(dut, bin_data, win_len)
    await burst_write(dut, bin_data, win_len, 10, thresh)
    



    


async def read_data(dut, gold, dout_width, dout_pt, thresh):
    await ClockCycles(dut.clk,2)
    count =0
    while(count < len(gold)):
        valid = int(dut.dout_valid.value)
        if(valid):
            out = int(dut.dout.value)
            out = two_comp_unpack(np.array(out), dout_width, dout_pt)
            assert (np.abs(out-gold[count])<thresh) , "Error! "
            print(str(out)+"\t"+str(gold[count]))
            count +=1
        await ClockCycles(dut.clk,1)


async def continous_write(dut, bin_data, win_len):
    dut.rst <= 1
    dut.din_valid<=0
    dut.din <=0
    await ClockCycles(dut.clk, 4)
    dut.rst <=0
    for i in range(len(bin_data)):
        dut.din <= int(bin_data[i])
        dut.din_valid <=1;
        await ClockCycles(dut.clk, 1)

async def burst_write(dut, bin_data, win_len, burst_len, thresh):
    dut.rst <= 1
    dut.din_valid <=0;
    dut.din <=0
    await ClockCycles(dut.clk, 4)
    dut.rst <= 0
    for i in range(len(bin_data)):
        if(i%burst_len==0):
            for j in range(2):
                dut.din_valid <=0
                await ClockCycles(dut.clk, 1)
        dut.din <= int(bin_data[i])
        dut.din_valid <=1;
        await ClockCycles(dut.clk, 1)


