import numpy as np
import h5py, cocotb, sys
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.clock import Clock
sys.path.append('../../cocotb_python')
from two_comp import two_comp_pack, two_comp_unpack
from itertools import cycle
import matplotlib.pyplot as plt

###
### Author: Sebastian Jorquera
###

@cocotb.test()
async def arte_beam_resize(dut, iters=2**12, din_width=18, din_point=17,
        dout_width=32, dout_point=20, filename='tone.hdf5'):
    #setup dut
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())

    dut.fft0_re0.value =0;  dut.fft0_re1.value=0;
    dut.fft0_re2.value =0;  dut.fft0_re3.value=0;
    dut.fft0_im0.value =0;  dut.fft0_im1.value=0;
    dut.fft0_im2.value =0;  dut.fft0_im3.value=0;
    dut.fft1_re0.value =0;  dut.fft1_re1.value=0;
    dut.fft1_re2.value =0;  dut.fft1_re3.value=0;
    dut.fft1_im0.value =0;  dut.fft1_im1.value=0;
    dut.fft1_im2.value =0;  dut.fft1_im3.value=0;
    dut.sync_in.value=0;

    await ClockCycles(dut.clk, 1)

    #get the data from the file
    f = h5py.File(filename, 'r')
    adc0 = np.array(f['adc0'])/2.**15
    adc1 = np.array(f['adc1'])/2.**15

    fft0_re = two_comp_pack((adc0.real).flatten(), din_width, din_point)
    fft0_im = two_comp_pack((adc0.imag).flatten(), din_width, din_point)
    fft1_re = two_comp_pack((adc1.real).flatten(), din_width, din_point)
    fft1_im = two_comp_pack((adc1.imag).flatten(), din_width, din_point)





