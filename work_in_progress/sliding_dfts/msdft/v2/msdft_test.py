import cocotb, struct
import numpy as np
from cocotb.clock import Clock
from cocotb.binary import BinaryValue
from cocotb.triggers import ClockCycles
import matplotlib.pyplot as plt
import msdft

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
async def msdft_test(dut, iters=180, dft_len=128, k=55, din_width=8,din_pt=7,
        dout_width=32,dout_pt=16):
    """ if you change k you need to create the corresponding twidd_init.hex
    """
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    din_int = din_width-din_pt
    dout_int = dout_width-dout_pt
    
    dut.delay_line<= dft_len-1

    dat = np.ones(iters)*0.5
    test1 = await msdft_rw(dut, dat, dft_len,k,din_width,din_pt,dout_width, dout_pt)


async def msdft_rw(dut, dat, dft_len=128, k=55, din_width=8,din_pt=7,
        dout_width=32,dout_pt=16):
    din_int = din_width-din_pt
    dout_int = dout_width-dout_pt
    dut.rst <=0;
    dut.din_valid <=0
    dut.din_re <=0; 
    dut.din_im<=0
    data = two_comp_pack(dat, din_width, din_int)
    await ClockCycles(dut.clk, 1)
    out_re = []
    out_im = []
    gold = msdft.msdft(dat, dft_len, k)
    for i in range(len(dat)):
        dut.din_re <= int(data[i])
        dut.din_im <= int(0)
        dut.din_valid <=1
        await ClockCycles(dut.clk, 1)
        valid = int(dut.dout_valid.value)
        if(valid):
            dout_re = np.array(int(dut.dout_re.value))
            dout_im = np.array(int(dut.dout_im.value))
            dout_re = two_comp_unpack(dout_re, dout_width, dout_int)
            dout_im = two_comp_unpack(dout_im, dout_width, dout_int)
            out_re.append(dout_re)
            out_im.append(dout_im)

    for i in range(len(out_re)):
        print(i)
        print("gold_re: %.4f \t gold im: %.4f"%(gold[i].real, gold[i].imag))
        print("out re: %.4f \t \tout im: %.4f"%(out_re[i], out_im[i]))
        print("")














