import cocotb, struct
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
from cocotb.binary import BinaryValue
import numpy as np
import matplotlib.pyplot as plt


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
async def dedispersor_test(dut):
    clk = Clock(dut.clk,10,units='ns')
    cocotb.fork(clk.start())
    np.random.seed(10)
    #test1 = await frb_test(dut)
    test2 = await frb_test2(dut)



async def frb_test(dut, n_chann=64):
    dut.ce <=0
    dut.rst <= 0
    dut.din_valid <=0
    dut.din <=0
    await ClockCycles(dut.clk, 4)
    curve = frb_values(n_chann)
    dat = curve.flatten()

    out_vals = []
    for i in range(n_chann**2):
        dut.din <= int(dat[i])
        dut.din_valid <= 1
        await ClockCycles(dut.clk,1)
        valid = dut.dout_valid.value
        if(valid):
            out_vals.append(int(dut.dout.value))
    for i in range(n_chann**2):
        dut.din <= int(dat[i])
        dut.din_valid <= 1
        await ClockCycles(dut.clk,1)
        valid = dut.dout_valid.value
        if(valid):
            out_vals.append(int(dut.dout.value))

    dut.din_valid <=1;
    dut.din <= 0
    for i in range(40*n_chann):
        await ClockCycles(dut.clk,1)
        valid = dut.dout_valid.value
        if(valid):
            out_vals.append(int(dut.dout.value))
    #np.savetxt('output', np.array(out_vals).flatten())
    #np.savetxt('input', dat)
    din = dat.reshape([64,-1])
    aux = np.array(out_vals)
    plt.imshow(aux[:10240].reshape([64,-1]), origin='bottom')
    plt.savefig("test.png")
    dout = np.array(out_vals[4096:8192])    ##i think that here appears the first dedispersed power
    dout = dout.reshape([64,-1])
    fig = plt.figure()
    ax1 = fig.add_subplot(121)
    ax2 = fig.add_subplot(122)
    ax1.imshow(din, origin='bottom')
    ax2.imshow(dout, origin='bottom')
    #plt.show()
    plt.savefig("dedisp.png")
    plt.plot()


async def frb_test2(dut, n_chann=64, acc=2):
    """now we have idle cycles between each fft, ie simulate accumulations"""
    dut.ce <=0
    dut.rst <= 0
    dut.din_valid <=0
    dut.din <=0
    await ClockCycles(dut.clk, 4)
    curve = frb_values(n_chann)
    dat = curve.flatten()

    out_vals = []
    for l in range(2):
        for i in range(n_chann):
            for j in range(n_chann):
                dut.din <= int(dat[n_chann*i+j])
                dut.din_valid <=1
                await ClockCycles(dut.clk,1)
                #now between each channel we have 4 cycles without valid
                valid = dut.dout_valid.value
                if(valid):
                    out_vals.append(int(dut.dout.value))
                #dut.din_valid <= 0
                #await ClockCycles(dut.clk,4)
               
            for j in range(acc*n_chann):
                dut.din_valid <=0
                await ClockCycles(dut.clk,1)
                valid = dut.dout_valid.value
                if(valid):
                    out_vals.append(int(dut.dout.value))
    dut.din_valid <=1;
    dut.din <= 0
    for i in range(40*n_chann):
        await ClockCycles(dut.clk,1)
        valid = dut.dout_valid.value
        if(valid):
            out_vals.append(int(dut.dout.value))
    #np.savetxt('output', np.array(out_vals).flatten())
    #np.savetxt('input', dat)
    """
    din = dat.reshape([64,-1])
    aux = np.array(out_vals)
    plt.imshow(aux[:10240].reshape([64,-1]), origin='bottom')
    plt.savefig("test.png")
    dout = np.array(out_vals[4096:8192])    ##i think that here appears the first dedispersed power
    dout = dout.reshape([64,-1])
    fig = plt.figure()
    ax1 = fig.add_subplot(121)
    ax2 = fig.add_subplot(122)
    ax1.imshow(din, origin='bottom')
    ax2.imshow(dout, origin='bottom')
    #plt.show()
    plt.savefig("dedisp.png")
    plt.plot()
    """
