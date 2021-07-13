import cocotb, struct
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
import numpy as np
from two_comp import two_comp_pack, two_comp_unpack


async def write_cont(dut,din_width, din_pt, dout_width, dout_pt,vec_len, iters,thresh):
    """
    """
    gold_r11 = np.zeros(vec_len)
    gold_r22 = np.zeros(vec_len)
    gold_r12 = np.zeros(vec_len)
    dut.new_acc <= 1
    await ClockCycles(dut.clk,1)
    for i in range(iters):
        acc_len = np.random.randint(1, 32)
        #acc_len = 4
        re1 = np.random.random(size=[acc_len, vec_len])-0.5#(np.random.randn(acc_len, vec_len))
        im1 = np.random.random(size=[acc_len, vec_len])-0.5#(np.random.randn(acc_len, vec_len))
        re2 = np.random.random(size=[acc_len, vec_len])-0.5#(np.random.randn(acc_len, vec_len))
        im2 = np.random.random(size=[acc_len, vec_len])-0.5#(np.random.randn(acc_len, vec_len))
        dat1 = re1+1j*im1; dat2 = re2+1j*im2
        r11 = np.sum(dat1*np.conj(dat1), axis=0); 
        r12 = np.sum(dat1*np.conj(dat2), axis=0); 
        r22 = np.sum(dat2*np.conj(dat2), axis=0)
        din1_re = two_comp_pack(re1.flatten(), din_width, din_pt)
        din1_im = two_comp_pack(im1.flatten(), din_width, din_pt)
        din2_re = two_comp_pack(re2.flatten(), din_width, din_pt)
        din2_im = two_comp_pack(im2.flatten(), din_width, din_pt)
        gold_r11 = np.append(gold_r11, r11); gold_r12 = np.append(gold_r12, r12)
        gold_r22 = np.append(gold_r22, r22)
        dut.new_acc <=0
        for j in range(acc_len*vec_len-1):
            dut.din1_re <= int(din1_re[j]); dut.din1_im <= int(din1_im[j])
            dut.din2_re <= int(din2_re[j]); dut.din2_im <= int(din2_im[j])
            dut.din_valid <= 1
            await ClockCycles(dut.clk,1)
            valid = int(dut.dout_valid.value)
            if(valid):
                ##the first set of values are zeros
                await assertion(dut, gold_r11[0], gold_r22[0], gold_r12[0],dout_width, dout_pt, thresh)
                gold_r11 = np.delete(gold_r11,0); gold_r22 = np.delete(gold_r22,0)
                gold_r12 = np.delete(gold_r12,0)
        dut.new_acc <=1 
        dut.din1_re <= int(din1_re[-1]); dut.din1_im <= int(din1_im[-1])
        dut.din2_re <= int(din2_re[-1]); dut.din2_im <= int(din2_im[-1])
        dut.din_valid <= 1
        await ClockCycles(dut.clk,1)
        valid = int(dut.dout_valid.value)
        if(valid):
            ##the first set of values are zeros
            await assertion(dut, gold_r11[0], gold_r22[0], gold_r12[0],dout_width, dout_pt, thresh)
            gold_r11 = np.delete(gold_r11,0); gold_r22 = np.delete(gold_r22,0)
            gold_r12 = np.delete(gold_r12,0)



async def assertion(dut, r11,r22, r12, dout_width, dout_pt, thresh):
    out_r11= np.array(int(dut.r11.value))
    out_r22= np.array(int(dut.r22.value))
    out_r12_re= np.array(int(dut.r12_re.value))
    out_r12_im= np.array(int(dut.r12_im.value))
    rtl_r11 = two_comp_unpack(out_r11, dout_width,dout_pt)
    rtl_r22 = two_comp_unpack(out_r22, dout_width,dout_pt)
    rtl_r12_re = two_comp_unpack(out_r12_re, dout_width,dout_pt)
    rtl_r12_im = two_comp_unpack(out_r12_im, dout_width,dout_pt)
    assert ((rtl_r11-r11)<thresh), ("Error, r11:%i gold:%i"%(rtl_r11, r11))
    assert ((rtl_r22-r22)<thresh), ("Error, r22:%i gold:%i"%(rtl_r22, r22))
    assert ((rtl_r12_re-r12.real)<thresh), ("Error, r12_re:%i gold:%i"%(rtl_r12_re, r12.real))
    assert ((rtl_r12_im-r12.imag)<thresh), ("Error, r12_re:%i gold:%i"%(rtl_r12_im, r12.imag))





@cocotb.test()
async def correlator_test(dut, vec_len=64, iters=10, din_width=16, din_pt=14, 
        dout_width=32, dout_pt=16, thresh=0.01):
    #setup dut
    din_int = din_width-din_pt
    cocotb.fork(Clock(dut.clk, 10, units='ns').start())
    dut.new_acc <=0
    dut.din1_re <=0; dut.din1_im <=0;
    dut.din2_re <=0; dut.din2_im <=0;
    dut.din_valid <=0;
    await ClockCycles(dut.clk,1)
    np.random.seed(10)
    acc_len = np.random.randint(1, 32)
    print(acc_len)
    await write_cont(dut, din_width, din_pt, dout_width, dout_pt, vec_len, iters, thresh)

