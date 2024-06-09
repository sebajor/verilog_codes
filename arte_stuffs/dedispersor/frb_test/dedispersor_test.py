import cocotb, struct
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
import numpy as np
import matplotlib.pyplot as plt

###
### Author: Sebastian Jorquera
###

def frb_curve(DM, f1, f2, n_samp=8192):
    """
     inputs:
        DM in pc*cm**3
        f1, f2 in mhz
     outputs:
        f in MHz
        t in seconds
    """
    #normalizo todo, con accumulacion se debiese poder
    #ti = 4.149*10**3*DM*f1**(-2)
    #tf = 4.149*10**3*DM*f2**(-2)
    ti = f1**(-2)
    tf = f2**(-2)
    t = np.linspace(ti,tf,n_samp)
    #f = np.sqrt(4.149*10**3*DM/t)
    f = np.sqrt(1/t)
    #t = 4.149*10**3*DM*f**(-2)
    return [t-t[-1],f]


def frb_values(n_chann=64):
    curve = np.zeros([n_chann, n_chann])
    t,f = frb_curve(1, 1800,1200,n_chann)
    f_bin = 600./n_chann
    bins = np.round((f-1200)/f_bin)
    mask = np.where(bins>n_chann-1)
    bins[mask] = n_chann-1
    #revisar!!!!
    for i in range(n_chann):
        curve[i,int(bins[i])] = 1
    return curve


@cocotb.test()
async def dedispersor_test(dut, n_chann=64, cont=0, back=4, 
        write_iters=10, read_iters=8192*4):
    clk = Clock(dut.clk,10,units='ns')
    cocotb.fork(clk.start())
    np.random.seed(10)
    #initialize dut
    dut.din.value =0
    dut.rst.value =0
    dut.din_valid.value =0
    dut.ce.value = 0

    await ClockCycles(dut.clk,10)
    
    #create input
    curve = frb_values(n_chann)
    dat = curve.flatten()

    cocotb.fork(write_data(dut, dat, cont, back, write_iters))
    dout, acc = await read_data(dut, read_iters)

    din = dat.reshape([64,-1])
    
    plt.imshow(dout.reshape([-1, 64]), origin='lower')
    plt.title('dedispersor output')
    plt.savefig('dedisp_out.png')
    plt.close()

    plt.plot(acc)
    plt.savefig('Integrated power')
    plt.close()

    fig = plt.figure()
    ax1 = fig.add_subplot(121); ax2 = fig.add_subplot(122)
    ax1.imshow(din, origin='lower')
    ax1.set_title('Input data')
    ax2.imshow(dout[4096:8192].reshape([64,-1]), origin='lower')
    ax2.set_title('Dedispersed')
    plt.savefig('dedisp.png')
    plt.close()




async def write_data(dut, data, cont, back, iters):
    if(cont):
        for j in range(iters):
            for i in range(len(data)):
                dut.din.value = int(data[i])
                dut.din_valid.value = 1
                await ClockCycles(dut.clk,1)
    else:
        for j in range(iters):
            for i in range(len(data)):
                dut.din.value = int(data[i])
                dut.din_valid.value = 1
                await ClockCycles(dut.clk,1)
                dut.din_valid.value =0
                await ClockCycles(dut.clk,back)

async def read_data(dut, iters):
    count =0
    dout = np.zeros(iters)
    acc_out = []
    while(count<iters):
        valid = int(dut.dout_valid.value)
        if(valid):
            dout[count] = int(dut.dout.value)
            count +=1
        acc_val = int(dut.integ_valid.value)
        if(acc_val):
            acc_out.append(int(dut.integ_pow.value))
        await ClockCycles(dut.clk, 1)
    acc_out = np.array(acc_out)
    return dout, acc_out
