import numpy as np
from two_comp import two_comp_pack, two_comp_unpack
import struct, cocotb
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
from cocotb.binary import BinaryValue

@cocotb.test()
async def comb_test(dut, iters=128, win_len=12, din_width=32, din_pt=31):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    din_int = din_width-din_pt
    np.random.seed(10)
    dat = np.random.random(iters)-0.5
    dut.delay_line <= (win_len-1)
    #test = await continous_test(dut,dat, win_len, din_width, din_pt, thresh=0.05)
    test = await burst_test(dut, dat, win_len, din_width, din_pt, burst_len=6, thresh=0.5)

async def continous_test(dut, dat, win_len, din_width, din_pt, thresh):
    data = two_comp_pack(dat,din_width, din_pt)
    dut.rst <= 0
    dut.din_valid <= 0
    dut.din <=0
    await ClockCycles(dut.clk,4)
    dut.rst <= 0
    gold_val = np.zeros(win_len)
    gold_values = []
    out_values = []
    for i in range(len(dat)):
        dut.din <= int(data[i])
        dut.din_valid <=1
        gold_val = np.roll(gold_val,1)
        gold_val[0] = dat[i]
        await ClockCycles(dut.clk,1)
        valid = dut.dout_valid.value
        if(valid):
            #gold_values.append(np.sum(gold_val)/len(gold_val))
            out = np.array(int(dut.dout.value))
            out = two_comp_unpack(out, din_width+1, din_pt)
            out_values.append(out)
    #we have a 2 delay between the gold and output values
    for i in range(len(out_values)-2):
        #print("gold: %0.5f"%gold_values[i])
        #print("out: %0.5f \n"%out_values[i+1])
        assert (np.abs(gold_values[i]-out_values[i+1])<thresh), "fail in {}".format(i)
    return 1




async def burst_test(dut, dat, win_len, din_width, din_pt, burst_len, thresh):
    data = two_comp_pack(dat,din_width, din_pt)
    dut.rst <= 0
    dut.din_valid <= 0
    dut.din <=0
    await ClockCycles(dut.clk,4)
    dut.rst <= 0
    gold_val = np.zeros(win_len)
    gold_values = []
    out_values = []
    for i in range(len(dat)):
        if(i%burst_len==0):
            for j in range(2):
                dut.din_valid <=0
                await ClockCycles(dut.clk,1)
                valid = int(dut.dout_valid.value)
                if(valid):
                    out = np.array(int(dut.dout.value))
                    out = two_comp_unpack(out, din_width+1, din_pt)
                    out_values.append(out)
        dut.din <= int(data[i])
        dut.din_valid <=1
        gold_values.append(dat[i]-gold_val[-1])
        gold_val = np.roll(gold_val,1)
        gold_val[0] = dat[i] 
        await ClockCycles(dut.clk,1)
        valid = int(dut.dout_valid.value)
        #gold_values.append(np.sum(gold_val)/len(gold_val))
        if(valid):
            out = np.array(int(dut.dout.value))
            out = two_comp_unpack(out, din_width+1, din_pt)
            out_values.append(out)
    #we have a 2 delay between the gold and output values
    for i in range(len(out_values)-1):
        #print(i)
        #print("gold: %0.5f"%(gold_values[i]))
        #print("out: %0.5f \n"%(out_values[i+1]))
        assert (np.abs(gold_values[i]-out_values[i+1])<thresh), "fail in {}".format(i)
    return 1



