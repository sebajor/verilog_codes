import numpy as np
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
from cocotb.binary import BinaryValue
import cocotb
from two_comp import *

@cocotb.test()
async def parallel_perceptron_test(dut, din_width=16, din_pt=15,parallel=4, w_width=16, w_pt=15,
        dout_width=48, dout_pt=30, n_weigth=64, iters=10):
    
    dout_width = dout_width+np.log2(parallel)
    clk = Clock(dut.clk, 10, 'ns')
    cocotb.fork(clk.start())
    np.random.seed(10)
    dut.din <=0
    dut.din_valid<=0
    dut.rst <= 1
    await ClockCycles(dut.clk, 3)
    w0 = np.loadtxt('w/w10.hex').astype(int)
    w0 = two_comp_unpack(w0, w_width, w_pt)
    w1 = np.loadtxt('w/w11.hex').astype(int)
    w1 = two_comp_unpack(w1, w_width, w_pt)
    w2 = np.loadtxt('w/w12.hex').astype(int)
    w2 = two_comp_unpack(w2, w_width, w_pt)
    w3 = np.loadtxt('w/w13.hex').astype(int)
    w3 = two_comp_unpack(w3, w_width, w_pt)
    w = [w0, w1,w2,w3]
    din = np.random.random([n_weigth, iters, parallel])-0.5
    out_vals = []
    for i in range(iters):
        iter_data = din[:,i,:]
        dut.din_valid <=1;
        dut.rst <=0
        for j in range(n_weigth):
            dat_b = two_pack_multiple(iter_data[j,:], din_width, din_pt)
            dut.din <= int(dat_b)
            #print(dat_b)
            await ClockCycles(dut.clk, 1)
            val = int(dut.acc_valid.value)
            if(val):
                out = np.array(int(dut.acc_out.value))
                out = two_comp_unpack(out, dout_width, dout_pt)
                out_vals.append(out)


    for i in range(len(out_vals)):
        gold = 0
        for j in range(parallel):
            gold = gold + np.sum(w[j]*din[:,i,j])
        print("gold: %.4f \t hdl: %.4f" %(gold, out_vals[i]))
