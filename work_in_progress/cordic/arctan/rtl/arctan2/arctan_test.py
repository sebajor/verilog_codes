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
async def arctan_test(dut, din_width=16, dout_width=16, iters=20):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    din_pt = din_width-1; dout_pt = dout_width-1
    din_int = 1; dout_pt = 1;
    y_test = two_comp_pack(np.array([0.3]), din_width, 1) 
    x_test = two_comp_pack(np.array([0.5]), din_width, 1) 
    dut.y <=int(y_test)#2**(din_pt-1)
    dut.x <=int(x_test)#2**(din_pt-1)
    dut.din_valid <=0
    await ClockCycles(dut.clk, 3)
    dut.din_valid <= 1;
    await ClockCycles(dut.clk, 1)
    dut.din_valid <= 0
    await ClockCycles(dut.clk, 60)

