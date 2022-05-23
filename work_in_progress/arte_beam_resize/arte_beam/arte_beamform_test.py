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
async def arte_beam_resize(dut, iters=2**16, din_width=18, din_point=17,
        dout_width=20, dout_point=16, shift=10, filename='arte_tone.hdf5'):
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

    fft0_re = two_comp_pack((adc0.real).T.flatten(), din_width, din_point)
    fft0_im = two_comp_pack((adc0.imag).T.flatten(), din_width, din_point)
    fft1_re = two_comp_pack((adc1.real).T.flatten(), din_width, din_point)
    fft1_im = two_comp_pack((adc1.imag).T.flatten(), din_width, din_point)
    
    din_data = [fft0_re, fft0_im, fft1_re, fft1_im]
    
    beam = adc0+adc1
    pow_beam = (beam*np.conj(beam)).real*2**shift


    cocotb.fork(write_data(dut, din_data))
    #await read_flag_signal(dut, beam.T.flatten(), iters,din_width, din_point, 1, 2**10)
    cocotb.fork(casting_warining(dut))
    rtl_pow = await read_power_signals(dut, pow_beam.T.flatten(), iters, dout_width, dout_point, 1)
    np.savetxt("rtl_pow.txt", rtl_pow)

    
async def write_data(dut, din_data):
    dut.sync_in.value = 1
    await ClockCycles(dut.clk,1)
    dut.sync_in.value = 0
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
        await ClockCycles(dut.clk,1)

async def casting_warining(dut):
    while(1):
        error = int(dut.cast_warning.value)
        assert (error==0)
        await ClockCycles(dut.clk,1)


async def read_power_signals(dut, gold, iters, dout_width, dout_point, thresh):
    count =0;
    valid=0;
    dout = np.zeros(4*iters)
    while(count <iters):
        sync_out = int(dut.sync_pow_resize.value)
        if(valid):
            pow0 = int(dut.pow0.value)
            pow1 = int(dut.pow1.value)
            pow2 = int(dut.pow2.value)
            pow3 = int(dut.pow3.value)
            out = two_comp_unpack(np.array([pow0,pow1,pow2,pow3]), dout_width, dout_point)
            print("rtl: %.2f \t gold: %.2f" %(out[0], gold[4*count]))
            print("rtl: %.2f \t gold: %.2f" %(out[1], gold[4*count+1]))
            print("rtl: %.2f \t gold: %.2f" %(out[2], gold[4*count+2]))
            print("rtl: %.2f \t gold: %.2f" %(out[3], gold[4*count+3]))
            assert(np.abs(out[0]-gold[4*count])<thresh)
            assert(np.abs(out[1]-gold[4*count+1])<thresh)
            assert(np.abs(out[2]-gold[4*count+2])<thresh)
            assert(np.abs(out[3]-gold[4*count+3])<thresh)
            dout[4*count] = out[0];   dout[4*count+1] = out[1]
            dout[4*count+2] = out[2]; dout[4*count+3] = out[3]
            count+=1
        if(sync_out):
            valid = 1
        await ClockCycles(dut.clk, 1)
    return dout

    
async def read_flag_signal(dut, gold, iters,dout_width, dout_point, thresh, mult):
    count=0
    valid=0
    while(count<iters):
        sync_out = int(dut.sig_sync.value)
        if(valid):
            beam0_re = int(dut.flag_re0.value)
            beam1_re = int(dut.flag_re1.value)
            beam2_re = int(dut.flag_re2.value)
            beam3_re = int(dut.flag_re3.value)
            beam0_im = int(dut.flag_im0.value)
            beam1_im = int(dut.flag_im1.value)
            beam2_im = int(dut.flag_im2.value)
            beam3_im = int(dut.flag_im3.value)
            out = np.array([beam0_re, beam1_re, beam2_re, beam3_re,
                            beam0_im, beam1_im, beam2_im, beam3_im])
            out = two_comp_unpack(out, dout_width, dout_point)
            print("rtl_re: %.2f \t gold_re: %.2f" %(out[0]*mult, gold[4*count].real*mult))
            print("rtl_re: %.2f \t gold_re: %.2f" %(out[1]*mult, gold[4*count+1].real*mult))
            print("rtl_re: %.2f \t gold_re: %.2f" %(out[2]*mult, gold[4*count+2].real*mult))
            print("rtl_re: %.2f \t gold_re: %.2f" %(out[3]*mult, gold[4*count+3].real*mult))
            print("rtl_im: %.2f \t gold_im: %.2f" %(out[4]*mult, gold[4*count].imag*mult))
            print("rtl_im: %.2f \t gold_im: %.2f" %(out[5]*mult, gold[4*count+1].imag*mult))
            print("rtl_im: %.2f \t gold_im: %.2f" %(out[6]*mult, gold[4*count+2].imag*mult))
            print("rtl_im: %.2f \t gold_im: %.2f" %(out[7]*mult, gold[4*count+3].imag*mult))
            assert(np.abs(out[0]*mult-gold[4*count].real*mult) < thresh) 
            assert(np.abs(out[1]*mult-gold[4*count+1].real*mult) < thresh) 
            assert(np.abs(out[2]*mult-gold[4*count+2].real*mult) < thresh) 
            assert(np.abs(out[3]*mult-gold[4*count+3].real*mult) < thresh) 
            assert(np.abs(out[4]*mult-gold[4*count].imag*mult) < thresh) 
            assert(np.abs(out[5]*mult-gold[4*count+1].imag*mult) < thresh) 
            assert(np.abs(out[6]*mult-gold[4*count+2].imag*mult) < thresh) 
            assert(np.abs(out[7]*mult-gold[4*count+3].imag*mult) < thresh) 
            count +=1
        if(sync_out):
            valid = 1
        await ClockCycles(dut.clk, 1)





