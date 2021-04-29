import numpy as np
import struct, cocotb
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
from cocotb.binary import BinaryValue


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
async def quad_root_test(dut,iters=128, din_width=16, din_pt=15, dout_width=16, dout_pt=13):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    din_int = din_width-din_pt
    dout_int = dout_width-dout_pt
    np.random.seed(10)
    b = np.random.random(iters)-0.5
    c = np.random.random(iters)-0.5
    #b = np.ones(iters)*(-0.4792)
    #c = np.ones(iters)*-0.4514
    b_bin = two_comp_pack(b, din_width, din_int)
    c_bin = two_comp_pack(c, din_width, din_int)
    dut.b <=0
    dut.c<=0
    dut.din_valid <=0
    await ClockCycles(dut.clk, 5)
    x1_vals = []
    x2_vals = []
    for i in range(iters):
        dut.b <= int(b_bin[i])
        dut.c <= int(c_bin[i])
        dut.din_valid <= 1
        await ClockCycles(dut.clk,1)
        valid = int(dut.dout_valid.value)
        if(valid):
            out = np.array(int(dut.x1.value))
            out = two_comp_unpack(out, dout_width, dout_int)
            x1_vals.append(out)
            out = np.array(int(dut.x2.value))
            out = two_comp_unpack(out, dout_width, dout_int)
            x2_vals.append(out)
    gold_out = []
    b_real = []; c_real = []
    for i in range(len(b)):
        gold = np.roots([1, b[i], c[i]])
        if(np.iscomplex(gold).sum()==0):
            gold_out.append(gold)
            b_real.append(b[i])
            c_real.append(c[i])

    for i in range(len(x1_vals)):
        #gold_val = np.roots([1, b[i], c[i]])
        outs = np.sort([x1_vals[i], x2_vals[i]])
        gold_vals = np.sort(gold_out[i])
        print("x1_gold: %.4f \t x1_fpga: %.4f" %(gold_vals[0], outs[0]))
        print("x2_gold: %.4f \t x2_fpga: %.4f" %(gold_vals[1], outs[1]))
        print("")
        #print("b: %.4f c:%.4f"%(b_real[i],c_real[i]))
        #print(gold_out[i])
        #print("x1: %.4f\t x2: %.4f" %(x1_vals[i], x2_vals[i]))
        #print("\n")

