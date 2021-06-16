import numpy as np
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
from cocotb.binary import BinaryValue
import cocotb


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
async def perceptron_test(dut, din_width=16, din_pt=15, w_width=16, w_pt=15, 
        dout_width=48, dout_pt=30, n_weight=64, iters=10):
    din_int = din_width-din_pt
    clk = Clock(dut.clk, 10, 'ns')
    cocotb.fork(clk.start())
    np.random.seed(10)
    dut.din <=0
    dut.din_valid<=0
    dut.rst <= 1
    await ClockCycles(dut.clk, 3)
    weights = np.loadtxt('w11.hex').astype(int)
    w = two_comp_unpack(weights, w_width, w_pt)
    #din = np.ones([n_weight, iters])*0.4
    din = np.random.random([n_weight, iters])-0.5
    out_vals = []
    for i in range(iters):
        din_b = two_comp_pack(din[:,i],din_width, din_pt)
        dut.din_valid <= 1;
        dut.rst <=0
        for j in range(n_weight):
            dut.din <= int(din_b[j])
            await ClockCycles(dut.clk, 1)
            val = int(dut.acc_valid.value)
            if(val):
                out = np.array(int(dut.acc_out.value))
                out = two_comp_unpack(out, dout_width, dout_pt)
                out_vals.append(out)
    for i in range(len(out_vals)):
        asd = np.sum(w*din[:,i])
        #print(out_vals[i])
        print("gold: %.4f \t hdl: %.4f"%(asd, out_vals[i]))


