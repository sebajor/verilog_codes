import numpy as np
import h5py, cocotb, sys
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.clock import Clock
sys.path.append('../../../cocotb_python')
from two_comp import two_comp_pack, two_comp_unpack
from itertools import cycle
import matplotlib.pyplot as plt

###
### Author:Sebastian Jorquera
###

@cocotb.test()
async def arte_rebin_test(dut, iters=2**14, din_width=20, din_point=16,
        dout_width=32, shift=10, filename='arte_tone.hdf5'):
    dout_point = din_point
    #setup dut
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())

    dut.pow0.value = 0
    dut.pow1.value = 0
    dut.pow2.value = 0
    dut.pow3.value = 0
    dut.sync_in.value=0;
    dut.cnt_rst.value = 0

    await ClockCycles(dut.clk, 1)

    #get the data from the file
    f = h5py.File(filename, 'r')
    adc0 = np.array(f['adc0'])/2.**15
    adc1 = np.array(f['adc1'])/2.**15

    beam = adc0+adc1
    pow_beam = (beam*np.conj(beam)).real*2**shift
    
    input_data = pow_beam.T.flatten()*2.**din_point
    gold = np.sum(pow_beam.reshape([-1,8*4, 512]), axis=1).T.flatten()

    cocotb.fork(write_data(dut, input_data))
    rtl = await read_data(dut,gold, 66, dout_width, dout_point, 1)
    dut.cnt_rst.value = 1
    await ClockCycles(dut.clk,1)
    dut.cnt_rst.value = 0
    await ClockCycles(dut.clk, 10)
    rtl = await read_data(dut,gold, iters, dout_width, dout_point, 1)
    np.savetxt('rtl_pow.txt', rtl)

    


async def write_data(dut, din_data):
    dut.sync_in.value = 1
    await ClockCycles(dut.clk,1)
    dut.sync_in.value = 0
    count = 0
    for i in range(len(din_data)//4):
        dut.pow0.value = int(din_data[4*i])
        dut.pow1.value = int(din_data[4*i+1])
        dut.pow2.value = int(din_data[4*i+2])
        dut.pow3.value = int(din_data[4*i+3])
        count += 1
        if(count==2**10):
            count= 0
            dut.sync_in.value = 1
        else:
            dut.sync_in.value =0
        await ClockCycles(dut.clk,1)


        

async def read_data(dut, gold, iters, dout_width, dout_point, thresh):
    count =0
    dout_data = np.zeros(iters)
    while(count<iters):
        valid = int(dut.dout_valid.value)
        if(valid):
            dout = int(dut.dout.value)/2.**dout_point
            dout_data[count] = dout
            print("rtl: %.2f \t gold:%.2f" %(dout, gold[count]))
            assert (np.abs(dout-gold[count])<thresh)
            count +=1
        await ClockCycles(dut.clk,1)
    return dout_data
        

    

