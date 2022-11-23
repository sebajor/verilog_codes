import numpy as np
import cocotb, sys
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.clock import Clock
sys.path.append('../../../cocotb_python')
from two_comp import two_comp_pack, two_comp_unpack
import ipdb


###
### Author:Sebastian Jorquera
###

@cocotb.test()
async def spectrometer_lane_test(dut, iters=5, din_width=18, din_point=17,vector_len=512,
        dout_width=64, dout_point=34, acc_len=32, shift=0, thresh=0.5):
    
    #setup dut
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    
    dut.din_re.value =0; dut.din_im.value =0;
    dut.sync_in.value =0
    dut.cnt_rst.value =0
    dut.acc_len.value = acc_len

    await ClockCycles(dut.clk, 5)
    dut.cnt_rst.value = 1;
    await ClockCycles(dut.clk,10)
    dut.cnt_rst.value = 0
    await ClockCycles(dut.clk,10)
    
    ##create data
    np.random.seed(10)
    dat_re = np.random.random(size=(vector_len, acc_len*iters))
    dat_im = np.random.random(size=(vector_len, acc_len*iters))
    #dat_re = np.tile(np.arange(vector_len)/vector_len,acc_len*iters).reshape((acc_len*iters, vector_len)).T
    #dat_im = np.zeros((vector_len, acc_len*iters))
    
    dat = dat_re+1j*dat_im 

    dat_re_b = two_comp_pack(dat_re.T.flatten(), din_width, din_point)
    dat_im_b = two_comp_pack(dat_im.T.flatten(), din_width, din_point)
    dat_b = np.array((dat_re_b, dat_im_b))
    
    gold = dat*np.conj(dat)
    gold = np.sum(gold.reshape([vector_len, -1, acc_len]), axis=2)
    gold = np.abs(gold.T.flatten())
    
    cocotb.fork(write_data(dut, dat_b, vector_len))
    await read_data(dut,gold,dout_width, dout_point, thresh)


async def write_data(dut, dat_b, vec_len):
    dut.sync_in.value = 0
    await ClockCycles(dut.clk, 1)
    dut.sync_in.value = 1
    dut.din_valid.value = 1
    await ClockCycles(dut.clk,1)
    dut.sync_in.value = 0
    for i in range(len(dat_b[1])):
        dut.din_re.value = int(dat_b[0][i])
        dut.din_im.value = int(dat_b[1][i])
        await ClockCycles(dut.clk,1)

async def read_data(dut, gold, dout_width, dout_point,thresh):
    count=0
    while(count < len(gold)):
        warn = int(dut.ovf_flag.value)
        assert (warn==0), "Overflow!"
        valid = int(dut.dout_valid.value)
        if(valid):
            dout = np.array(int(dut.dout.value))
            dout = two_comp_unpack(dout, dout_width, dout_point)
            addr = int(dut.dout_addr.value)
            print("addr:%i \t rtl: %.4f gold:%.4f" %(addr, dout, gold[count]))
            assert (np.abs(dout-gold[count])<thresh)
            count +=1
        await ClockCycles(dut.clk, 1)
    return 1
