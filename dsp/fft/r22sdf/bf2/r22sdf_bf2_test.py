import numpy as np
import cocotb
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
import cocotb_test.simulator
import pytest
import sys
sys.path.append('../../../../cocotb_python/')
from two_comp import two_comp_pack, two_comp_unpack
sys.path.append('../')
from python_test import BF_II

###
### Author: Sebastian jorquera
###


@cocotb.test()
async def r22sdf_bf2_test(dut, din_width=16, din_point=14, fifo_depth=16, iters=128, thresh=1e-3):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    dut.rst.value =0
    dut.din_valid.value = 0
    dut.din_re.value = 0
    dut.din_im.value = 0
    await ClockCycles(dut.clk, 3)
    np.random.seed(123)
    
    din_re = np.random.random(iters)-0.5#np.ones(iters)*0.5
    din_im = np.random.random(iters)-0.5#np.ones(iters)*0.25

    din_re_b = two_comp_pack(din_re, din_width, din_point)
    din_im_b = two_comp_pack(din_im, din_width, din_point)

    din_b = [din_re_b, din_im_b]
    
    gold = []
    bf2 = BF_II(fifo_depth)
    for re,im in zip(din_re, din_im):
        bf2.process(re+1j*im)
        gold.append(bf2.dout)
    gold = np.array(gold[fifo_depth:])

    cocotb.start_soon(write_data(dut, din_b))
    await read_data(dut, gold, din_width+1, din_point, thresh)

async def write_data(dut, data):
    for re,im in zip(data[0], data[1]):
        dut.din_re.value = int(re)
        dut.din_im.value = int(im)
        dut.din_valid.value = 1
        await ClockCycles(dut.clk,1)

async def read_data(dut, gold, dout_width, dout_point, thresh):
    count = 0;
    while(count < len(gold)):
        valid = int(dut.dout_valid.value)
        if(valid):
            dout_re = int(dut.dout_re.value)
            dout_im = int(dut.dout_im.value)
            dout_re, dout_im = two_comp_unpack(np.array([dout_re, dout_im]), 
                                                dout_width,dout_point)
            print("real: gold: %.2f \t rtl:%.2f" %(gold[count].real, dout_re))
            print("imag: gold: %.2f \t rtl:%.2f" %(gold[count].imag, dout_im))
            assert (np.abs(gold[count].real-dout_re)<thresh), "Error real part!"
            assert (np.abs(gold[count].imag-dout_im)<thresh), "Error imag part!"
            count +=1
        await ClockCycles(dut.clk,1)








