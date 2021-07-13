import numpy as np
import cocotb
from cocotb.clock import Clock
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
async def signes_acc_test(dut, din_width=16, dout_width=32, acc_len=10,iters=128):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    dut.din <=0
    dut.din_valid <=0
    dut.acc_done <=0
    await ClockCycles(dut.clk, 1)

    #data
    dout_vals =[]
    data = np.random.randint(0,2**8,[acc_len, iters])*(-1)**(np.random.randint(0,2,[acc_len, iters]))
    for i in range(iters):
        dat = two_comp_unpack(data[:,i],din_width,din_width)
        dut.acc_done <=1
        for j in range(acc_len):
            dut.din <= int(dat[j])
            dut.din_valid <=1
            await ClockCycles(dut.clk, 1)
            dut.acc_done <= 0;
            valid = int(dut.dout_valid.value)
            if(valid):
                dout_vals.append(int(dut.dout.value))
    dout_vals = np.array(dout_vals)
    dout_vals = two_comp_unpack(dout_vals, dout_width, dout_width)
    gold_vals = np.sum(data, axis=0)
    for i in range(len(dout_vals)-1):
        #print("gold: %i \t rtl:%i"%(gold_vals[i], dout_vals[i+1]))
        assert ((dout_vals[i+1]-gold_vals[i])==0), "error in {}".format(i)
