import cocotb, struct
import numpy as np
from cocotb.clock import Clock
from cocotb.binary import BinaryValue
from cocotb.triggers import ClockCycles



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
async def complex_mult_test(dut, iters=32, din1_width=16, din1_pt=14, din2_width=16, din2_pt=14, thresh=0.005):
    clk = Clock(dut.clk, 10,units='ns')
    cocotb.fork(clk.start())
    din1_int = din1_width-din1_pt
    din2_int = din2_width-din2_pt
    dout_width = din1_width+din2_width+1
    dout_pt = din1_pt+din2_pt
    dout_int = dout_width-dout_pt

    np.random.seed(10)
    din1_re = np.random.random(iters)-0.5
    din1_im = np.random.random(iters)-0.5
    din2_re = np.random.random(iters)-0.5
    din2_im = np.random.random(iters)-0.5
   
    re1 = two_comp_pack(din1_re, din1_width, din1_int)
    im1 = two_comp_pack(din1_im, din1_width, din1_int)
    re2 = two_comp_pack(din2_re, din2_width, din2_int)
    im2 = two_comp_pack(din2_im, din2_width, din2_int)

    dut.din1_re <=0; dut.din1_im <= 0
    dut.din2_re <=0; dut.din2_im <= 0
    dut.din_valid <=0
    
    re_vals = []
    im_vals = []
    for i in range(iters):
        dut.din_valid <=1
        dut.din1_re <= int(re1[i])
        dut.din1_im <= int(im1[i])
        dut.din2_re <= int(re2[i])
        dut.din2_im <= int(im2[i])
        await ClockCycles(dut.clk, 1)
        valid = dut.dout_valid
        if(int(valid)):
            re_val = np.array(int(dut.dout_re.value))
            im_val = np.array(int(dut.dout_im.value))
            re_val = two_comp_unpack(re_val, dout_width, dout_int)
            im_val = two_comp_unpack(im_val, dout_width, dout_int)
            re_vals.append(re_val)
            im_vals.append(im_val)
    re_vals = np.array(re_vals)
    im_vals = np.array(im_vals)
    for i in range(len(re_vals)):
        gold_re = (din1_re[i]*din2_re[i]-din1_im[i]*din2_im[i])
        gold_im = (din1_re[i]*din2_im[i]+din1_im[i]*din2_re[i])
        #print("re gold: %.4f \t re sim: %.4f" %((din1_re[i]*din2_re[i]-din1_im[i]*din2_im[i]), re_vals[i]))
        #print("im gold: %.4f \t im sim: %.4f" %((din1_re[i]*din2_im[i]+din1_im[i]*din2_re[i]), im_vals[i]))
        assert (np.abs(gold_re-re_vals[i])<thresh), "fail in avg {}".format(i)
        assert (np.abs(gold_im-im_vals[i])<thresh), "fail in avg {}".format(i)


