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
async def correlator_lane_test(dut, iters=5, din_width=18, din_point=17,vector_len=512,
        dout_width=64, dout_point=34, acc_len=18, shift=0, thresh=0.5):
    
    #setup dut
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    
    dut.din0_re.value =0; dut.din0_im.value =0;
    dut.din1_re.value =0; dut.din1_im.value =0;
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
    dat_re = np.random.random(size=(vector_len, acc_len*iters))-0.5
    dat_im = np.random.random(size=(vector_len, acc_len*iters))-0.5
    dat0 = dat_re+1j*dat_im 

    dat_re_b = two_comp_pack(dat_re.T.flatten(), din_width, din_point)
    dat_im_b = two_comp_pack(dat_im.T.flatten(), din_width, din_point)
    dat0_b = np.array((dat_re_b, dat_im_b))
    
    dat_re = np.random.random(size=(vector_len, acc_len*iters))-0.5
    dat_im = np.random.random(size=(vector_len, acc_len*iters))-0.5
    dat1 = dat_re+1j*dat_im 

    dat_re_b = two_comp_pack(dat_re.T.flatten(), din_width, din_point)
    dat_im_b = two_comp_pack(dat_im.T.flatten(), din_width, din_point)
    dat1_b = np.array((dat_re_b, dat_im_b))


    gold_r12 = dat0*np.conj(dat1)
    gold_r12 = np.sum(gold_r12.reshape([vector_len, -1, acc_len]), axis=2)
    gold_r12 = gold_r12.T.flatten()

    gold_r11 = dat0*np.conj(dat0)
    gold_r11 = np.sum(gold_r11.reshape([vector_len, -1, acc_len]), axis=2)
    gold_r11 = np.abs(gold_r11.T.flatten())
    
    gold_r22 = dat1*np.conj(dat1)
    gold_r22 = np.sum(gold_r22.reshape([vector_len, -1, acc_len]), axis=2)
    gold_r22 = np.abs(gold_r22.T.flatten())

    gold = [gold_r11, gold_r22, gold_r12]
    
    cocotb.fork(write_data(dut, dat0_b, dat1_b, vector_len))
    await read_data(dut,gold,dout_width, dout_point, thresh)


async def write_data(dut, dat0_b,dat1_b, vec_len):
    dut.sync_in.value = 0
    await ClockCycles(dut.clk, 1)
    dut.sync_in.value = 1
    dut.din_valid.value = 1
    await ClockCycles(dut.clk,1)
    dut.sync_in.value = 0
    for i in range(len(dat0_b[1])):
        dut.din0_re.value = int(dat0_b[0][i])
        dut.din0_im.value = int(dat0_b[1][i])
        dut.din1_re.value = int(dat1_b[0][i])
        dut.din1_im.value = int(dat1_b[1][i])
        await ClockCycles(dut.clk,1)

async def read_data(dut, gold, dout_width, dout_point,thresh):
    count=0
    while(count < len(gold[0])):
        warn = int(dut.ovf_flag.value)
        assert (warn==0), "Overflow!"
        valid = int(dut.dout_valid.value)
        if(valid):
            dout = np.array(int(dut.r11.value))
            dout = two_comp_unpack(dout, dout_width, dout_point)
            addr = int(dut.dout_addr.value)
            print("addr:%i \t rtl: %.4f gold:%.4f" %(addr, dout, gold[0][count]))
            assert (np.abs(dout-gold[0][count])<thresh)
            dout = np.array(int(dut.r22.value))
            dout = two_comp_unpack(dout, dout_width, dout_point)
            print("\t rtl: %.4f gold:%.4f" %(dout, gold[1][count]))
            assert (np.abs(dout-gold[1][count])<thresh)

            dout = np.array([0,int(dut.r12_re.value)])
            dout_re = two_comp_unpack(dout, dout_width, dout_point)
            ##dont ask me why but this work...(surely its for the masking)
            dout_re = dout_re[1]
            dout = np.array([0,int(dut.r12_im.value)])
            dout_im = two_comp_unpack(dout, dout_width, dout_point)
            dout_im = dout_im[1]
            print("\t rtl: {0} gold:{1}".format(dout_re+1j*dout_im, gold[2][count]))
            assert (np.abs(dout_re-gold[2][count].real)<thresh)
            assert (np.abs(dout_im-gold[2][count].imag)<thresh)
            count +=1
        await ClockCycles(dut.clk, 1)
    return 1
