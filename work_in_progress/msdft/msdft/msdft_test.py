import cocotb, sys
import numpy as np
sys.path.append('../')
import msdft
sys.path.append('../../../cocotb_python')
from two_comp import two_comp_pack, two_comp_unpack, two_pack_multiple
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

###
### Author: Sebastian Jorquera
###

@cocotb.test()
async def msdft_test(dut, iters=180, dft_len=128, k=55, din_width=8, din_pt=7,
        dout_width=32, dout_pt=21, thresh=1):
    #init config
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    axi_clk = Clock(dut.axi_clock, 5, units='ns')
    cocotb.fork(axi_clk.start())
    #set some values
    dut.delay_line.value = dft_len-1
    dut.rst.value =1
    dut.din_valid.value = 0
    dut.din_re.value =0
    dut.din_im.value =0
    dut.bram_dat.value =0
    dut.bram_addr.value =0
    dut.bram_we.value =0
    await ClockCycles(dut.clk, 5)
    dut.rst.value =0
    await ClockCycles(dut.clk, 5)

    ##input data
    n = np.arange(iters)
    dat_re = 0.9*np.cos(2*np.pi*k*n/dft_len)
    dat_im = 0.1*np.cos(2*np.pi*k*n/dft_len)
    din_re = two_comp_pack(dat_re, din_width, din_pt)
    din_im = two_comp_pack(dat_im, din_width, din_pt)
    gold = msdft.msdft(dat_re+1j*dat_im, dft_len,k)
    #cocotb.fork(read_data(dut, gold, dout_width, dout_pt, thresh))
    #await continous_write(dut, din_re, din_im)
    
    ###charge a new twiddle factor with a new dft len
    dut.rst.value =1
    dut.din_valid.value =0
    dft_len = 72
    k = 20
    await ClockCycles(dut.clk,5)
    dut.delay_line.value = dft_len-1
    await ClockCycles(dut.clk,5)

    await write_twidd_factor(dut, dft_len, k)
    #dat_re = 0.9*np.cos(2*np.pi*k*n/dft_len)
    #dat_im = 0.2*np.cos(2*np.pi*k*n/dft_len)
    angle = 0
    dat = 0.9*np.exp(1j*(2*np.pi*k*n/dft_len+np.deg2rad(angle)))
    dat_re = dat.real; dat_im = dat.imag
    din_re = two_comp_pack(dat_re, din_width, din_pt)
    din_im = two_comp_pack(dat_im, din_width, din_pt)
    gold = msdft.msdft(dat_re+1j*dat_im, dft_len,k)
    
    ##after charge the wights rst to match the gold values
    dut.rst.value = 1
    await ClockCycles(dut.clk,5)
    dut.rst.value = 0

    cocotb.fork(read_data(dut, gold, dout_width, dout_pt, thresh))
    await continous_write(dut, din_re, din_im)

    
async def read_data(dut, gold, dout_width, dout_pt, thresh):
    await ClockCycles(dut.clk,2)
    count =0
    while(count < len(gold)):
        valid = int(dut.dout_valid.value)
        if(valid):
            out_re = int(dut.dout_re.value)
            out_im = int(dut.dout_im.value)
            out_re = two_comp_unpack(np.array(out_re), dout_width, dout_pt)
            out_im = two_comp_unpack(np.array(out_im), dout_width, dout_pt)
            assert (np.abs(out_re-gold[count].real)<thresh) , "Error! "
            assert (np.abs(out_im-gold[count].imag)<thresh) , "Error! "
            print(str(out_re+1j*out_im)+"\t"+str(gold[count]))
            count +=1
        await ClockCycles(dut.clk,1)


async def continous_write(dut, dat_re, dat_im):
    for i in range(len(dat_re)):
        dut.din_re.value = int(dat_re[i])
        dut.din_im.value = int(dat_im[i])
        dut.din_valid.value = 1
        await ClockCycles(dut.clk,1)


async def burst_write(dut, dat_re, dat_im, burst_len):
    for i in range(len(dat_re)):
        if(i%burst_len==0):
            for j in range(2):
                dut.din_valid.value =0
                await ClockCycles(dut.clk, 1)
            dut.din_re.value = int(dat_re[i])
            dut.din_im.value = int(dat_im[i])
            dut.din_valid.value =1
            await ClockCycles(dut.clk, 1)


async def write_twidd_factor(dut, dft_len, k):
    """write the twiddle factors into the module
    """
    n =np.arange(dft_len)
    twidd = np.exp(-1j*2*np.pi*n*k/dft_len)
    twidd_re = twidd.real
    twidd_im = twidd.imag
    aux = np.array([twidd_im, twidd_re])    #check order !!! im is the low, re is high
    dut.din_valid.value =1;
    dut.din_re.value =0; dut.din_im.value = 0;    ##this is better to reset everything
    dut.rst.value = 0;
    await ClockCycles(dut.clk, 128)
    dut.din_valid.value =0
    await ClockCycles(dut.clk, 20)
    dut.bram_we.value = 1
    for i in range(len(twidd_re)):
        dat = two_pack_multiple(aux[:, i], 16, 14)
        dut.bram_dat.value = int(dat)
        dut.bram_addr.value = int(i)
        await ClockCycles(dut.axi_clock, 1)
    #now read the output
    dut.bram_we.value =0
    await ClockCycles(dut.axi_clock, 2)
    for i in range(len(twidd_re)):
        dut.bram_addr.value = int(i)
        await ClockCycles(dut.axi_clock, 1)

