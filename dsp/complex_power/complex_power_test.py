import sys
sys.path.append('../../cocotb_python')
import numpy as np
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
import cocotb
from two_comp import two_comp_pack, two_comp_unpack

###
###     Author:Sebastian Jorquera
###

@cocotb.test()
async def complex_power_test(dut,iters=128, din_width=16, din_pt=4, thresh=0.6,
        cont=0, burst_len=10):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())

    dout_width = 2*din_width+1
    dout_pt = 2*din_pt

    #dut setup
    dut.din_re.value = 0
    dut.din_im.value = 0
    dut.din_valid.value =0
    await ClockCycles(dut.clk, 10)

    np.random.seed(23)
    din_re = (np.random.random(iters)-0.5)*2**2
    din_im = (np.random.random(iters)-0.5)*2**2

    gold = (din_re+1j*din_im)*(din_re-1j*din_im)

    din_re = two_comp_pack(din_re, din_width, din_pt)
    din_im = two_comp_pack(din_im, din_width, din_pt)

    data = [din_re, din_im]

    cocotb.fork(read_data(dut, gold, dout_width, dout_pt, thresh))
    await write_data(dut, data, cont, burst_len)


async def write_data(dut, data, cont, burst_len):
    if(cont):
        for i in range(len(data[0])):
            dut.din_valid.value = 1
            dut.din_re.value = int(data[0][i])
            dut.din_im.value = int(data[1][i])
            await ClockCycles(dut.clk, 1)
        dut.din_valid.value =0
    else:
        count =0
        for i in range(len(data[0])):
            dut.din_valid.value = 1
            dut.din_re.value = int(data[0][i])
            dut.din_im.value = int(data[1][i])
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
            dout = int(dut.dout.value)
            dout = two_comp_unpack(np.array([dout]),dout_width,dout_pt)
            print("gold: %.2f \t rtl:%.2f" %(gold[count].real, dout))
            assert (np.abs(gold[count].real-dout)<thresh), "Error!"
            count +=1
        await ClockCycles(dut.clk,1 )



