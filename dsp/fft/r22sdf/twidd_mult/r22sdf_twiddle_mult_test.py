import numpy as np
import cocotb
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
import cocotb_test.simulator
import pytest
import itertools
import sys
sys.path.append('../../../../cocotb_python/')
from two_comp import two_comp_pack, two_comp_unpack


def get_stage_twiddle_factors(stage_number):
    N = stage_number*2
    subset_index = stage_number//2
    twiddles = np.ones(N, dtype=complex)
    W_n = np.exp(-1j*2*np.pi/N)
    twiddles[subset_index:subset_index*2] = W_n**(np.arange(subset_index)*2)
    twiddles[subset_index*2:subset_index*3] = W_n**(np.arange(subset_index))
    twiddles[subset_index*3:] = W_n**(np.arange(subset_index)*3)
    return twiddles


@cocotb.test()
async def r22sdf_twiddle_mult_test(dut, din_width=16, din_point=14, fft_size=64, iters=2*128, thresh=1e-3):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    dut.rst.value =0
    dut.din_valid.value = 0
    dut.din_re.value = 0
    dut.din_im.value = 0
    await ClockCycles(dut.clk, 3)
    np.random.seed(123)

    din_re = np.random.random(iters)-0.
    #din_re = np.ones(iters)*0.5
    din_im = np.random.random(iters)-0.5#
    #din_im = np.zeros(iters)
    din =din_re+1j*din_im

    din_re_b = two_comp_pack(din_re, din_width, din_point)
    din_im_b = two_comp_pack(din_im, din_width, din_point)

    din_b = [din_re_b, din_im_b]
    
    gold = []
    twiddles = get_stage_twiddle_factors(fft_size//2) 
    print(twiddles)
    for dat, twid in zip(din, itertools.cycle(twiddles)):
        gold.append(dat*twid)
    gold= np.array(gold)

    cocotb.start_soon(write_data(dut, din_b))
    await read_data(dut, gold, din_width, din_point, thresh)




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
            print(count)
            print("real: gold: %.2f \t rtl:%.2f" %(gold[count].real, dout_re))
            print("imag: gold: %.2f \t rtl:%.2f" %(gold[count].imag, dout_im))
            print("")
            assert (np.abs(gold[count].real-dout_re)<thresh), "Error real part!"
            assert (np.abs(gold[count].imag-dout_im)<thresh), "Error imag part!"
            count +=1
        await ClockCycles(dut.clk,1)
    




    
