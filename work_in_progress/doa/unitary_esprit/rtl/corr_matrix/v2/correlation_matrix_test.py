import cocotb, struct
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
from cocotb.binary import BinaryValue
import numpy as np


def two_comp_pack(values, n_bits, n_int):
    """ Values are a numpy array witht the actual values
        that you want to set in the dut port
        n_bits: number of bits
        n_int: integer part of the representation
    """
    bin_pt = n_bits-n_int
    quant_data = (2**bin_pt*values).astype(int)
    ovf = (quant_data>2**(n_bits-1)-1)&(quant_data<2**(n_bits-1))
    if(ovf.any()):
        raise "Cannot represent one value with that representation"
    mask = np.where(quant_data<0)
    quant_data[mask] = 2**(n_bits)+quant_data[mask]
    return quant_data


def two_comp_unpack(values, n_bits, n_int):
    """Values are integer values (to test if its enough to take
    get_value_signed to obtain the actual value...
    """
    bin_pt = n_bits-n_int
    mask = values>2**(n_bits-1)-1 ##negative values
    out = values.copy()
    out[mask] = values[mask]-2**n_bits
    out = 1.*out/(2**bin_pt)
    return out

@cocotb.test()
async def correlation_matrix_test(dut, acc_len=5, vec_len=64, iters=10,din_width=16, din_pt=14,dout_width=32, dout_pt=16, thresh=0.01):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    din_int = din_width-din_pt
    dut.new_acc <=0
    dut.din1_re<=0; dut.din1_im<=0;
    dut.din2_re<=0; dut.din2_im<=0;
    dut.din_valid<=0
    dut.rst<=0
    await ClockCycles(dut.clk,1)
    np.random.seed(10)
    #re1 = np.ones([vec_len, acc_len])*(-0.5)
    #im1 = np.ones([vec_len, acc_len])*0
    #re2 = np.ones([vec_len, acc_len])*(0)
    #im2 = np.ones([vec_len, acc_len])*(1)
    re1 = np.random.rand(vec_len, acc_len)*2**(din_int-1)
    im1 = np.random.rand(vec_len, acc_len)*2**(din_int-1)
    re2 = np.random.rand(vec_len, acc_len)*2**(din_int-1)
    im2 = np.random.rand(vec_len, acc_len)*2**(din_int-1)
    test1 = await write_signed(dut, re1,im1,re2,im2,din_width, din_pt, dout_width, dout_pt, wait=0)
    din1 = re1+1j*im1
    din2 = re2+1j*im2
    gold_r11 = np.sum(din1*np.conj(din1), axis=1)
    gold_r22 = np.sum(din2*np.conj(din2), axis=1)
    gold_r12 = np.sum(din1*np.conj(din2), axis=1)
    for i in range(iters):
        [r11, r22, r12_re, r12_im] = await write_signed(dut, re1,im1,re2,im2,din_width, din_pt, dout_width, dout_pt, wait=0)
        for j in range(len(r11)):
            #print("gold r11  : %.4f \t out r11  :%.4f" %(gold_r11[j].real, r11[j]))
            #print("gold r22  : %.4f \t out r22  :%.4f" %(gold_r22[j].real, r22[j]))
            #print("gold r12re: %.4f \t out r12re:%.4f" %(gold_r12[j].real, r12_re[j]))
            #print("gold r12im: %.4f \t out r12im:%.4f" %(gold_r12[j].imag, r12_im[j]))
            #print("\n")
            assert (np.abs(gold_r11[j].real-r11[j])<thresh), "fail in r11 {},{}".format(i,j)
            assert (np.abs(gold_r22[j].real-r22[j])<thresh), "fail in r22 {},{}".format(i,j)
            assert (np.abs(gold_r12[j].real-r12_re[j])<thresh), "fail in r12re {},{}".format(i,j)
            assert (np.abs(gold_r12[j].imag-r12_im[j])<thresh), "fail in r12im {},{}".format(i,j)
        din1 = re1+1j*im1
        din2 = re2+1j*im2
        gold_r11 = np.sum(din1*np.conj(din1), axis=1)
        gold_r22 = np.sum(din2*np.conj(din2), axis=1)
        gold_r12 = np.sum(din1*np.conj(din2), axis=1)
        re1 = np.random.rand(vec_len, acc_len)*2**(din_int-1)
        im1 = np.random.rand(vec_len, acc_len)*2**(din_int-1)
        re2 = np.random.rand(vec_len, acc_len)*2**(din_int-1)
        im2 = np.random.rand(vec_len, acc_len)*2**(din_int-1)
    """
    [r11, r22, r12_re, r12_im] = await write_signed(dut, re1,im1,re2,im2,din_width, din_pt, dout_width, dout_pt, wait=0)
    [r11, r22, r12_re, r12_im] = await write_signed(dut, re1,im1,re2,im2,din_width, din_pt, dout_width, dout_pt, wait=0)
    din1 = re1+1j*im1
    din2 = re2+1j*im2
    gold_r11 = np.sum(din1*np.conj(din1), axis=1)
    gold_r22 = np.sum(din2*np.conj(din2), axis=1)
    gold_r12 = np.sum(din1*np.conj(din2), axis=1)
    for j in range(len(r11)):
        #print(j)
        #print("gold r11  : %.4f \t out r11  :%.4f" %(gold_r11[j].real, r11[j]))
        #print("gold r22  : %.4f \t out r22  :%.4f" %(gold_r22[j].real, r22[j]))
        #print("gold r12re: %.4f \t out r12re:%.4f" %(gold_r12[j].real, r12_re[j]))
        #print("gold r12im: %.4f \t out r12im:%.4f" %(gold_r12[j].imag, r12_im[j]))
        #print("\n")
        assert (np.abs(gold_r11[j].real-r11[j])<thresh), "fail in r11 {}".format(j)
        assert (np.abs(gold_r22[j].real-r22[j])<thresh), "fail in r22 {}".format(j)
        assert (np.abs(gold_r12[j].real-r12_re[j])<thresh), "fail in r12re {}".format(j)
        assert (np.abs(gold_r12[j].imag-r12_im[j])<thresh), "fail in r12im {}".format(j)
"""
    
        





async def write_signed(dut, re1,im1,re2,im2,din_width,din_pt,
        dout_width,dout_pt, wait=64):
    """
        dat: [vec_len, acc_len]
        wait: wait between each vec_len
    """
    din_int = din_width-din_pt
    dout_int = dout_width-dout_pt
    #dut.new_acc <= 1
    #dut.din_valid <= 0
    #await ClockCycles(dut.clk,1)
    #dut.new_acc <= 0
    dut.new_acc <=1;
    vec_len, acc_len = re1.shape
    r11 = []
    r22 = []
    r12_re = []
    r12_im = []
    for i in range(acc_len):
        din1re = two_comp_pack(re1[:,i], din_width, din_int)
        din1im = two_comp_pack(im1[:,i], din_width, din_int)
        din2re = two_comp_pack(re2[:,i], din_width, din_int)
        din2im = two_comp_pack(im2[:,i], din_width, din_int)
        #print(data)
        
        for j in range(vec_len):
            #if((i==(acc_len-1)) and (j==(vec_len-1))):
            #    dut.new_acc <= 1;   #put one in the last sample
            dut.din1_re <= int(din1re[j])
            dut.din1_im <= int(din1im[j])
            dut.din2_re <= int(din2re[j])
            dut.din2_im <= int(din2im[j])
            dut.din_valid <=1
            await ClockCycles(dut.clk,1)
            dut.new_acc <=0;
            valid = int(dut.dout_valid.value)
            if(valid):
                r11_val = np.array(int(dut.r11.value))
                r22_val = np.array(int(dut.r22.value))
                r12_re_val = np.array(int(dut.r12_re.value))
                r12_im_val = np.array(int(dut.r12_im.value))
                r11.append(r11_val)
                r22.append(r22_val)
                r12_re.append(r12_re_val)
                r12_im.append(r12_im_val)
        for j in range(wait):
            dut.din_valid <= 0
            await ClockCycles(dut.clk, 1)
            valid = int(dut.dout_valid.value)
            if(valid):
                r11_val = np.array(int(dut.r11.value))
                r22_val = np.array(int(dut.r22.value))
                r12_re_val = np.array(int(dut.r12_re.value))
                r12_im_val = np.array(int(dut.r12_im.value))
                r11.append(r11_val)
                r22.append(r22_val)
                r12_re.append(r12_re_val)
                r12_im.append(r12_im_val)
    out_r11 = np.array(r11)
    out_r22 = np.array(r22)
    out_r12_re = np.array(r12_re)
    out_r12_im = np.array(r12_im)
        
    ##out_r11 = two_comp_unpack(out_r11, dout_width, dout_int)
    ##out_r22 = two_comp_unpack(out_r22, dout_width, dout_int)
    out_r11 = out_r11/(2.**dout_pt)
    out_r22 = out_r22/(2.**dout_pt)
    out_r12_re = two_comp_unpack(out_r12_re, dout_width, dout_int)
    out_r12_im = two_comp_unpack(out_r12_im, dout_width, dout_int)
    
    out_vals = [out_r11, out_r22, out_r12_re, out_r12_im]
    return out_vals

