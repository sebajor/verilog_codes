import numpy as np
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from two_comp import two_comp_pack, two_comp_unpack, two_pack_multiple


@cocotb.test()
async def neuron_test(dut, din_width=16, din_pt=15, parallel=4, w_width=16, w_pt=15,
        dout_width = 16, dout_pt=14, n_weigth=64, iters=10):
    bias = np.array([0.1])
    bias_width = 48+2
    bias_pt = 30
    bias_bin = two_comp_pack(bias, bias_width, bias_pt)
 
    clk = Clock(dut.clk, 10, 'ns')
    cocotb.fork(clk.start())
    np.random.seed(10)
    dut.din <=0
    dut.din_valid <=0
    dut.rst <=1
    dut.bias <= int(bias_bin)
    await ClockCycles(dut.clk,3)
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
            val = int(dut.dout_valid.value)
            if(val):
                out = np.array(int(dut.dout.value))
                out = two_comp_unpack(out, dout_width, dout_pt)
                out_vals.append(out)

    ##if gold > 1, we saturate to 1, but hte fraction part is free
    ##if gold < 1, the value is zero
    for i in range(len(out_vals)):
        gold = 0
        for j in range(parallel):
            gold = gold + np.sum(w[j]*din[:,i,j])
        print("gold: %.4f \t hdl: %.4f" %(gold+bias, out_vals[i]))
