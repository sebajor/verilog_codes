import numpy as np
import h5py, cocotb, sys
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.clock import Clock
sys.path.append('../../../cocotb_python')
from two_comp import two_comp_pack, two_comp_unpack

###
### Author: Sebastian Jorquera
### This testbench is intended to be used with real data that is saved in
### a hdf5 file
###

@cocotb.test()
async def resize_data_test(dut, iters=16384, din_width=18, din_point=17,
        shift=6,dout_width=9, dout_point=8, filename='../tone.hdf5',
        thresh=0.3):
    #setup dut
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())    

    dut.din0_re.value =0;   dut.din0_im.value =0
    dut.din1_re.value =0;   dut.din1_im.value =0
    dut.din_valid.value=0;
    dut.sync_in.value=0;

    await ClockCycles(dut.clk,5)
    ##get the data from the file
    f = h5py.File(filename, 'r')
    adc0 = np.array(f['adc0'])/2.**15
    adc1 = np.array(f['adc1'])/2.**15
    adc3 = np.array(f['adc3'])/2.**15
    
    beam = (adc0+adc1).T.flatten()
    rfi = adc3.T.flatten()
    
    beam_re = two_comp_pack(beam.real, din_width, din_point)
    beam_im = two_comp_pack(beam.imag, din_width, din_point)
    
    rfi_re = two_comp_pack(rfi.real, din_width, din_point)
    rfi_im = two_comp_pack(rfi.imag, din_width, din_point)

    gold = [beam*2**shift, rfi*2**shift]

    cocotb.fork(write_data(dut,beam_re, beam_im, rfi_re, rfi_im))
    await read_data(dut, gold,iters, dout_width, dout_point, thresh)
    

async def write_data(dut, beam_re, beam_im, rfi_re, rfi_im):
    dut.sync_in.value = 1
    await ClockCycles(dut.clk,1)
    dut.sync_in.value = 0
    dut.din_valid.value = 1
    for i in range(len(beam_re)):
        dut.din0_re.value = int(beam_re[i])
        dut.din0_im.value = int(beam_im[i])
        dut.din1_re.value = int(rfi_re[i])
        dut.din1_im.value = int(rfi_im[i])
        await ClockCycles(dut.clk,1)

async def read_data(dut, gold, iters,dout_width, dout_point, thresh):
    count =0;
    while(count < iters):
        warn =  int(dut.warning.value)
        assert (warn ==0), 'Warning!!'
        valid = int(dut.dout_valid.value)
        if(valid):
            beam_re = int(dut.dout0_re.value)
            beam_im = int(dut.dout0_im.value)
            rfi_re = int(dut.dout1_re.value)
            rfi_im = int(dut.dout1_im.value)
            beam_re, beam_im, rfi_re, rfi_im = two_comp_unpack(
                    np.array([beam_re, beam_im, rfi_re, rfi_im]), dout_width,
                    dout_point)
            assert (np.abs(beam_re-gold[0][count].real)<thresh)
            assert (np.abs(beam_im-gold[0][count].imag)<thresh)
            assert (np.abs(rfi_re-gold[1][count].real)<thresh)
            assert (np.abs(rfi_im-gold[1][count].imag)<thresh)
            count+=1;
        await ClockCycles(dut.clk, 1)

            
    
