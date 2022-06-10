import numpy as np
import h5py, cocotb, sys
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.clock import Clock
sys.path.append('../../../cocotb_python')
from two_comp import two_comp_pack, two_comp_unpack
from itertools import cycle
import matplotlib.pyplot as plt

###
### Author: Sebastian Jorquera
###

@cocotb.test()
async def arte_beam_resize(dut, iters=2**10, din_width=18, din_point=17,
        acc_len=32,dout_width=32, dout_point=15, shift=5, filename='freq_1607_70.hdf5',
        thresh=1):
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
    dut.acc_len.value = acc_len
    dut.cnt_rst.value = 0
    dut.config_flag.value =0
    dut.config_num.value = 0
    dut.config_en.value = 0
    await ClockCycles(dut.clk, 10)

    dut.cnt_rst.value = 1
    await ClockCycles(dut.clk,1)
    dut.cnt_rst.value = 0
    await ClockCycles(dut.clk,3)
    

    #get the data from the file
    f = h5py.File(filename, 'r')
    adc0 = np.array(f['adc0'])/2.**15
    adc1 = np.array(f['adc1'])/2.**15

    fft0_re = two_comp_pack((adc0.real).T.flatten(), din_width, din_point)
    fft0_im = two_comp_pack((adc0.imag).T.flatten(), din_width, din_point)
    fft1_re = two_comp_pack((adc1.real).T.flatten(), din_width, din_point)
    fft1_im = two_comp_pack((adc1.imag).T.flatten(), din_width, din_point)
    
    din_data = [fft0_re, fft0_im, fft1_re, fft1_im]

    beam = adc0+adc1
    pow_beam = (beam*np.conj(beam)).real*2**shift
    data_shape = pow_beam.shape
    rebin_beam = np.sum(pow_beam.reshape([-1,8*4, data_shape[-1]]), axis=1)
    rebin_acc = np.sum(rebin_beam.T.reshape([-1,acc_len, 64]), axis=1)
    gold = rebin_acc.flatten()

    cocotb.fork(write_data(dut, din_data))

    #await read_data(dut, gold, 66, dout_width, dout_point, thresh)
    #dut.cnt_rst.value = 1
    #await ClockCycles(dut.clk, 10)
    #dut.cnt_rst.value = 0
    #await ClockCycles(dut.clk,1)
    
    dout = await read_data(dut, gold, iters, dout_width, dout_point, thresh)
    np.savetxt('rtl_out.txt', dout)


async def write_data(dut, din_data):
    dut.sync_in.value = 1
    await ClockCycles(dut.clk,1)
    dut.sync_in.value = 0
    count =0
    for i in range(len(din_data[0])//4):
        dut.fft0_re0.value = int(din_data[0][4*i])
        dut.fft0_re1.value = int(din_data[0][4*i+1])
        dut.fft0_re2.value = int(din_data[0][4*i+2])
        dut.fft0_re3.value = int(din_data[0][4*i+3])
        dut.fft0_im0.value = int(din_data[1][4*i])
        dut.fft0_im1.value = int(din_data[1][4*i+1])
        dut.fft0_im2.value = int(din_data[1][4*i+2])
        dut.fft0_im3.value = int(din_data[1][4*i+3])
        dut.fft1_re0.value = int(din_data[2][4*i])
        dut.fft1_re1.value = int(din_data[2][4*i+1])
        dut.fft1_re2.value = int(din_data[2][4*i+2])
        dut.fft1_re3.value = int(din_data[2][4*i+3])
        dut.fft1_im0.value = int(din_data[3][4*i])
        dut.fft1_im1.value = int(din_data[3][4*i+1])
        dut.fft1_im2.value = int(din_data[3][4*i+2])
        dut.fft1_im3.value = int(din_data[3][4*i+3])
        count +=1
        if(count==2**10):
            count =0
            dut.sync_in.value = 1
        else:
            dut.sync_in.value = 0
        await ClockCycles(dut.clk,1)


async def casting_warining(dut):
    while(1):
        error = int(dut.cast_warning.value)
        assert (error==0)
        await ClockCycles(dut.clk,1)


async def read_data(dut, gold, iters, dout_width, dout_point, thresh):
    count =0
    dout_data = np.zeros(iters)
    while(count<iters):
        valid = int(dut.dout_valid.value)
        if(valid):
            dout = int(dut.dout.value)/2.**dout_point
            dout_data[count] = dout
            #print("rtl: %.2f \t gold:%.2f" %(dout, gold[count]))
            #assert (np.abs(dout-gold[count])<thresh)
            count +=1
        await ClockCycles(dut.clk,1)
    return dout_data 
