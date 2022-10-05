import cocotb, sys
import numpy as np
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
sys.path.append('../../cocotb_python')
from two_comp import two_comp_pack, two_comp_unpack, pack_multiple

###
###     Author: Sebastian Jorquera
###

@cocotb.test()
async def adc_clipping_detector_test(dut, iters=1024, din_width=8, parallel=8):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())

    dut.din0.value =0
    dut.din1.value =0
    dut.din2.value =0
    dut.din3.value =0
    dut.din4.value =0
    dut.din5.value =0
    dut.din6.value =0
    dut.din7.value =0
    dut.rst.value =1

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 5)
    
    ##generate the input data
    data = np.random.randint(-2**(din_width-2), 2**(din_width-2), iters*parallel)   #not saturated
    data = data.reshape([-1, parallel])
    
    np.random.seed(12)
    indices = np.random.randint(0,len(data), iters//10)
    indices = np.unique(indices//parallel)
    indices = np.sort(indices)[::3] ##to avoid having near indices.. we just care bcs
                                    ##the reset takes one cycle to take effect
                                    ##in the hw is not that important..
    print(indices)
    
    clip_values = [-2**(din_width-1), 2**(din_width-1)-1]
    sub_ind = np.arange(parallel)
    for ind in indices:
        clip = np.random.choice(clip_values)
        aux = np.random.choice(sub_ind)
        data[ind, aux] = clip
       
    data_b = two_comp_pack(data.flatten(),din_width, 0)
    data_b = data_b.reshape([-1, parallel])
    

    cocotb.fork(write_data(dut,data_b))
    await read_data(dut, indices)




async def write_data(dut, data):
    for i in range(data.shape[0]):
        dut.din0.value = int(data[i,0])
        dut.din1.value = int(data[i,1])
        dut.din2.value = int(data[i,2])
        dut.din3.value = int(data[i,3])
        dut.din4.value = int(data[i,4])
        dut.din5.value = int(data[i,5])
        dut.din6.value = int(data[i,6])
        dut.din7.value = int(data[i,7])
        await ClockCycles(dut.clk,1)

async def read_data(dut, indices):
    counter =0
    ind_count=0
    while(ind_count<len(indices)):
        dut.rst.value = 0
        ovf = int(dut.clip.value)
        if(ovf & (not(int(dut.rst.value)))):
            print("{:} {:}".format(counter, indices[ind_count]))
            ind_count+=1
            dut.rst.value = 1
        counter+=1
        await ClockCycles(dut.clk,1)


    
