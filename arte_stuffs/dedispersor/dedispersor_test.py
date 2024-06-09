import cocotb
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
import numpy as np
import matplotlib.pyplot as plt

###
### Author: Sebastian Jorquera
###

@cocotb.test()
async def dedispersor_test(dut, n_channels=64, cont=0, back=2, read_iters=8192):
    clk = Clock(dut.clk,10,units='ns')
    cocotb.fork(clk.start())

    #setup dut
    dut.rst.value = 0
    dut.din.value =0
    dut.din_valid.value =0

    await ClockCycles(dut.clk, 5)

    #generate test data
    dat = np.zeros([n_channels, n_channels])
    for i in range(n_channels):
        dat[i,i] = 3
    dat = dat.flatten()
    cocotb.fork(write_data(dut, dat, cont, back))
    dout = await read_data(dut, read_iters)

    fig = plt.figure()
    ax1 = fig.add_subplot(121)
    ax2 = fig.add_subplot(122)
    din = dat.reshape([n_channels,-1])
    dout = dout[4096:8192]  ##i think here appears
    dout = dout.reshape([n_channels,-1])
    ax1.imshow(din, origin='lower')
    ax1.set_title('DIN')
    ax2.imshow(dout, origin='lower')
    ax2.set_title('Dedispersed')
    plt.savefig('dedisp.png')



async def write_data(dut, data, cont, back):
    if(cont):
        for i in range(len(data)):
            dut.din.value = int(data[i])
            dut.din_valid.value = 1
            await ClockCycles(dut.clk,1)
        for i in range(len(data)):
            dut.din.value = int(data[i])
            dut.din_valid.value = 1
            await ClockCycles(dut.clk,1)
    else:
        for i in range(len(data)):
            dut.din.value = int(data[i])
            dut.din_valid.value = 1
            await ClockCycles(dut.clk,1)
            dut.din_valid.value =0
            await ClockCycles(dut.clk,back)
        for i in range(len(data)):
            dut.din.value = int(data[i])
            dut.din_valid.value = 1
            await ClockCycles(dut.clk,1)
            dut.din_valid.value =0
            await ClockCycles(dut.clk,back)

async def read_data(dut, iters):
    count =0
    dout = np.zeros(iters)
    while(count<iters):
        valid = int(dut.dout_valid.value)
        if(valid):
            dout[count] = int(dut.dout.value)
            count +=1
        await ClockCycles(dut.clk, 1)
    return dout


