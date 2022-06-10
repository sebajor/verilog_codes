import numpy as np
import cocotb, sys
from cocotb.triggers import ClockCycles, RisingEdge, Timer
from cocotb.clock import Clock
sys.path.append("../../../cocotb_python")
from two_comp import two_comp_pack, two_comp_unpack

###
### Author: Sebastian Jorquera
###


@cocotb.test()
async def fir_tap_dsp48_test(dut, din_width=16,din_pt=14, coeff_width=16, coeff_pt=14,
        dout_width=48, iters=128, thresh=0.005):
    dout_pt = din_pt+coeff_pt
    ##initialize signals
    clk = Clock(dut.clk, 10, units='us')
    cocotb.fork(clk.start())
    dut.pre_add1.value =0
    dut.pre_add2.value =0
    dut.din_valid.value =0
    dut.coeff.value =0
    dut.post_add.value =0
    ##data input
    np.random.seed(20)
    pre_add1 = np.random.random(iters)-0.5
    pre_add2 = np.random.random(iters)-0.5
    coeffs = np.random.random(iters)-0.5
    post_add = np.random.random(iters)-0.5
    #write data
    cocotb.fork(write_data(dut, pre_add1, pre_add2, coeffs, post_add,
        din_width,din_pt, coeff_width,coeff_pt,dout_width))
    await read_data(dut, pre_add1,pre_add2,coeffs,post_add, dout_width,
        dout_pt, thresh)

async def read_data(dut, pre_add1,pre_add2,coeffs,post_add, dout_width,
        dout_pt, thresh):
    gold = (pre_add1+pre_add2)*coeffs+post_add
    count = 0
    for i in range(len(pre_add1)):
        await ClockCycles(dut.clk,1)
        valid = int(dut.dout_valid.value)
        if(valid==1):
            out=np.array([int(dut.dout.value)])
            out = two_comp_unpack(out, dout_width, dout_pt)
            assert (np.abs(gold[count]-out[0])<thresh), 'Error'
            count +=1

async def write_data(dut, pre_add1, pre_add2, coeffs, post_add,
        din_width,din_pt, coeff_width,coeff_pt,dout_width):
    dout_pt = din_pt+coeff_pt
    pre_add1 = two_comp_pack(pre_add1, din_width, din_pt)
    pre_add2 = two_comp_pack(pre_add2, din_width, din_pt)
    post_add = two_comp_pack(post_add, dout_width, dout_pt)
    coeffs = two_comp_pack(coeffs, coeff_width, coeff_pt)
    for i in range(len(pre_add1)):
        dut.pre_add1.value = int(pre_add1[i])
        dut.pre_add2.value = int(pre_add2[i])
        dut.coeff.value = int(coeffs[i])
        dut.post_add.value = int(post_add[i])
        dut.din_valid.value =1
        await ClockCycles(dut.clk,1)



