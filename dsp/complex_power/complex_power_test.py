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
async def complex_power_test(dut, iters=20 ,din_width=16, din_int=4, thresh=0.002):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    
    #dut config
    dut.din_re <=0
    dut.din_im <=0
    dut.din_valid<=0
    await ClockCycles(dut.clk, 3)

    din_pt = din_width-din_int
    dout_width = 2*din_pt+1
    dout_pt = 2*din_pt
    dout_int = dout_width-dout_pt
    
    np.random.seed(10)
    din_re = (np.random.random(iters)-0.5)*2
    din_im = (np.random.random(iters)-0.5)*2

    re = two_comp_pack(din_re, din_width, din_int)
    im = two_comp_pack(din_im, din_width, din_int)
    
    out_vals = []
    for i in range(iters):
        dut.din_valid <=1
        dut.din_re <= int(re[i])
        dut.din_im <= int(im[i])
        await ClockCycles(dut.clk,1)
        valid = int(dut.dout_valid.value)
        if(valid):
            out = np.array(int(dut.dout.value))
            out = out/2.**(dout_pt)
            out_vals.append(out)
        dat = din_re+1j*din_im
        gold = dat*np.conj(dat)
        for i in range(len(out_vals)):
            assert (np.abs(gold[i]-out_vals[i])<thresh), "fail in {}".format(i)
            #print("gold:%.4f \t out:%.4f"%(gold[i], out_vals[i]))
    





