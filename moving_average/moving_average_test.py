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
async def moving_average_test(dut, iters=128, win_len=16, din_width=32, din_point=31):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    din_int = din_width-din_point
    #test1 = await cte_test(dut, 50, 10)
    #test2 = await sweep_test(dut, 50)
    np.random.seed(10)
    dat = np.random.random(20)-0.5
    test = await rnd_test(dut,dat, win_len, din_width, din_int, thresh=0.05)


async def rnd_test(dut, dat, win_len, din_width, din_int, thresh):
    data = two_comp_pack(dat,din_width, din_int)
    dut.rst <= 0
    dut.din_valid <= 0
    dut.din <=0
    await ClockCycles(dut.clk,4)
    dut.rst <= 0
    gold_val = np.zeros(win_len)
    gold_values = []
    out_values = []
    for i in range(len(dat)):
        dut.din <= int(data[i])
        dut.din_valid <=1
        gold_val = np.roll(gold_val,1)
        gold_val[0] = dat[i] 
        await ClockCycles(dut.clk,1)
        valid = dut.dout_valid.value
        if(valid):
            gold_values.append(np.sum(gold_val)/len(gold_val))
            out = np.array(int(dut.dout.value))
            out = two_comp_unpack(out, din_width, din_int)
            out_values.append(out)
    #we have a 2 delay between the gold and output values
    for i in range(len(out_values)-2):
        #print("gold: %0.5f"%gold_values[i])
        #print("out: %0.5f \n"%out_values[i+2])
        assert (np.abs(gold_values[i]-out_values[i])<thresh), "fail in {}".format(i)
    return 1


async def cte_test(dut, cycles, cte):
    dut.rst <=0;
    dut.din_valid <= 0;
    dut.din <= 0;
    await ClockCycles(dut.clk, 4)
    dut.rst <=0;
    dut.din_valid <= cte;
    dut.din <= 0;
    await ClockCycles(dut.clk, 10) 
    dut.din_valid <= cte;
    dut.din <=1
    out_vals = []
    for i in range(cycles):
        await ClockCycles(dut.clk,1)
        valid = dut.dout_valid.value
        if(valid):
            print(int(dut.dout.value))
            #out_vals.append(out)
    return 1


async def sweep_test(dut, cycles):
    dut.rst <=0;
    dut.din_valid <= 0;
    dut.din <= 0;
    await ClockCycles(dut.clk, 4)
    dut.rst <=0;
    dut.din_valid <= 1;
    dut.din <= 0;
    await ClockCycles(dut.clk, 10) 
    dut.din_valid <= 1;
    dut.din <=6
    out_vals = []
    for i in range(cycles):
        if(i%2):
            dut.din <= 10;
        else:
            dut.din <= 12;
        await ClockCycles(dut.clk,1)
        valid = dut.dout_valid.value
        if(valid):
            print(int(dut.dout.value))
            #out_vals.append(out)
    return 1



