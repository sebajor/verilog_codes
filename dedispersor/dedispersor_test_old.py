import cocotb, struct
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
from cocotb.binary import BinaryValue
import numpy as np
import matplotlib.pyplot as plt

@cocotb.test()
async def dedispersor_test(dut):
    clk = Clock(dut.clk,10,units='ns')
    cocotb.fork(clk.start())
    np.random.seed(10)
    test1 = await cte_test(dut,n_chann=64)



async def cte_test(dut, n_chann=8):
    dut.ce.value=0
    dut.rst.value=  0
    dut.din_valid.value= 0
    dut.din.value= 0
    await ClockCycles(dut.clk, 4)

    ##test data
    dat = np.zeros([n_chann,n_chann])
    for i in range(n_chann):
        dat[i,i] = 3
    dat = dat.flatten()

    out_vals = []
    for i in range(n_chann**2):
        dut.din.value=  int(dat[i])
        dut.din_valid.value=  1
        await ClockCycles(dut.clk,1)
        valid = dut.dout_valid.value
        if(valid):
            out_vals.append(int(dut.dout.value))
    for i in range(n_chann**2):
        dut.din.value=  int(dat[i])
        dut.din_valid.value=  1
        await ClockCycles(dut.clk,1)
        valid = dut.dout_valid.value
        if(valid):
            out_vals.append(int(dut.dout.value))

    dut.din_valid.value= 1;
    dut.din.value=  0
    for i in range(2*n_chann):
        await ClockCycles(dut.clk,1)
        valid = dut.dout_valid.value
        if(valid):
            out_vals.append(int(dut.dout.value))
    #np.savetxt('output', np.array(out_vals).flatten())
    #np.savetxt('input', dat)
    fig = plt.figure()
    ax1 = fig.add_subplot(121)
    ax2 = fig.add_subplot(122)
    din = dat.reshape([64,-1])
    dout = np.array(out_vals[4096:8192])    ##i think that here appears the first dedispersed power
    dout = dout.reshape([64,-1])
    ax1.imshow(din, origin='bottom')
    ax2.imshow(dout, origin='bottom')
    #plt.show()
    plt.savefig("dedisp.png")
    


