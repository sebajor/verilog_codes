import struct, cocotb
import numpy as np
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
from cocotb.binary import BinaryValue


def relu(din):
    """ function to calculate the gold values
        din: numpy array
    """
    mask = din>0
    out = din*mask
    return out

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
async def relu_test(dut, din_width=16, din_int=3, dout_width=8, dout_int=4,
                    iters=128, thresh=0.1):
    ##
    din_pt = din_width-din_int
    dout_pt = dout_width-dout_int
    types = ['b','h','i','q']
    din_type = types[int(din_width/8-1)]
    dout_type = types[int(dout_width/8-1)]
    
    ##
    np.random.seed(12)
    clk = Clock(dut.clk, 10, units="ns")
    cocotb.fork(clk.start())
    data = (np.random.random(iters)-0.5)*2**(din_int)
    data_b = two_comp_pack(data, din_width, din_int)
    quant_data = (2**din_pt*data).astype(int)/2.**din_pt

    gold_vals =relu(quant_data)
    out_vals = []

    for i in range(iters):
        dut.din_valid <= 1
        dut.din <= int(data_b[i])
        await ClockCycles(dut.clk, 1)
        valid = dut.dout_valid.value
        if(int(valid)):
            out_vals.append(int(dut.dout.value))
    
    out_vals = np.array(out_vals)
    result = two_comp_unpack(out_vals, dout_width, dout_int)
    for i in range(len(result)):
        #print("Python output: "+str(gold_vals[i]))
        #print("Verilog output: "+str(result[i]))
        assert (np.abs(gold_vals[i]-result[i])<thresh), "fail in {}".format(i)
    print("Pass!")




