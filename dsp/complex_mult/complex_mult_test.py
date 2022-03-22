import sys
sys.path.append('../../cocotb_python')
import numpy as np
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
import cocotb
from two_comp import two_comp_pack, two_comp_unpack

###
###     Author: Sebastian Jorquera
###
@cocotb.test()
async def complex_mult_test(dut, iters=128, din1_width=16, din1_pt=14, din2_width=16, din2_pt=14,
        cont=0, burst_len=10, thresh = 0.005):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())

    dout_width = din1_width+din2_width+1;
    dout_pt = din1_pt+din2_pt

    #setup dut
    dut.din1_re.value = 0
    dut.din1_im.value = 0
    dut.din2_re.value = 0
    dut.din2_im.value = 0
    dut.din_valid.value =0
    
    await ClockCycles(dut.clk, 10)
    
    #start values
    np.random.seed(3)
    din1_re = np.random.random(iters)-0.5
    din1_im = np.random.random(iters)-0.5
    din2_re = np.random.random(iters)-0.5
    din2_im = np.random.random(iters)-0.5

    gold = (din1_re+1j*din1_im)*(din2_re+1j*din2_im)
    
    din1_re = two_comp_pack(din1_re, din1_width, din1_pt)
    din1_im = two_comp_pack(din1_im, din1_width, din1_pt)
    din2_re = two_comp_pack(din2_re, din2_width, din2_pt)
    din2_im = two_comp_pack(din2_im, din2_width, din2_pt)
    
    data = [din1_re, din1_im, din2_re, din2_im]

    cocotb.fork(read_data(dut, gold, dout_width, dout_pt, thresh))
    await write_data(dut, data, cont, burst_len)

    
async def write_data(dut, data, cont, burst_len):
    if(cont):
        for i in range(len(data[0])):
            dut.din_valid.value = 1
            dut.din1_re.value = int(data[0][i])
            dut.din1_im.value = int(data[1][i])
            dut.din2_re.value = int(data[2][i])
            dut.din2_im.value = int(data[3][i])
            await ClockCycles(dut.clk, 1)
        dut.din_valid.value =0
    else:
        count =0
        for i in range(len(data[0])):
            dut.din_valid.value = 1
            dut.din1_re.value = int(data[0][i])
            dut.din1_im.value = int(data[1][i])
            dut.din2_re.value = int(data[2][i])
            dut.din2_im.value = int(data[3][i])
            await ClockCycles(dut.clk, 1)
            count +=1
            if( count==burst_len):
                count =0
                dut.din_valid.value = 0
                await ClockCycles(dut.clk, np.random.randint(20))
        dut.din_valid.value =0


async def read_data(dut, gold, dout_width, dout_pt, thresh):
    count =0
    while(count < len(gold)):
        valid = int(dut.dout_valid.value)
        if(valid):
            dout_re = int(dut.dout_re.value)
            dout_im = int(dut.dout_im.value)
            dout_re, dout_im = two_comp_unpack(np.array([dout_re, dout_im]), 
                                                dout_width,dout_pt)
            print("real: gold: %.2f \t rtl:%.2f" %(gold[count].real, dout_re))
            print("imag: gold: %.2f \t rtl:%.2f" %(gold[count].imag, dout_im))
            assert (np.abs(gold[count].real-dout_re)<thresh), "Error real part!"
            assert (np.abs(gold[count].imag-dout_im)<thresh), "Error imag part!"
            count +=1
        await ClockCycles(dut.clk,1 )





