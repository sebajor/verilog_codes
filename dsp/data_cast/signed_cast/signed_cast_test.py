import cocotb, struct
import numpy as np
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
from cocotb.binary import BinaryValue

def two_comp_pack(values, n_bits, bin_pt):
    """ Values are a numpy array witht the actual values
        that you want to set in the dut port
        n_bits: number of bits
        n_int: integer part of the representation
    """
    n_int = n_bits-bin_pt
    quant_data = (2**bin_pt*values).astype(int)
    ovf = (quant_data>2**(n_bits-1)-1)&(quant_data<2**(n_bits-1))
    if(ovf.any()):
        raise "Cannot represent one value with that representation"
    mask = np.where(quant_data<0)
    quant_data[mask] = 2**(n_bits)+quant_data[mask]
    return quant_data

def two_comp_unpack(values, n_bits, bin_pt):
    """Values are integer values (to test if its enough to take
    get_value_signed to obtain the actual value...
    """
    n_int = n_bits-bin_pt
    mask = values>2**(n_bits-1)-1 ##negative values
    out = values.copy()
    out[mask] = values[mask]-2**n_bits
    out = 1.*out/(2**bin_pt)
    return out

@cocotb.test()
async def signed_cast_test(dut, din_w=16, din_pt=12, dout_w=8, dout_pt=4, iters=10):
    din_int = din_w-din_pt
    clk = Clock(dut.clk, 10, 'ns')
    cocotb.fork(clk.start())
    np.random.seed(10)
    dut.din <=0
    dut.din_valid<=0
    await ClockCycles(dut.clk, 3)
    din = (np.random.random(iters)-0.5)*2**(din_int-1)
    #din  = np.ones(iters)*-5.5
    din_bin = two_comp_pack(din, din_w, din_pt)
    out_vals = []
    for i in range(iters):
        dut.din <= int(din_bin[i])
        dut.din_valid <= 1;
        await ClockCycles(dut.clk, 1)
        valid = dut.dout_valid.value
        if(int(valid)):
            out = dut.dout.value
            out_vals.append(int(out))
    out = np.array(out_vals)
    out = two_comp_unpack(out, dout_w, dout_pt)
    for i in range(len(out_vals)):
        print("%.4f \t %.4f" %(din[i], out[i]))
