import cocotb, struct
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb.binary import BinaryValue
import numpy as np


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
async def acc_test(dut, din_width=16, din_int=8, dout_width=32, dout_int=16, 
                   acc_len=30,iters=10 ,thresh=0.2):
    din_pt = din_width-din_int
    dout_pt = dout_width-dout_int
    np.random.seed(10)
    clock = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clock.start())
    print("Random input test") 
    data = (np.random.random([acc_len, iters])-0.5)*2**(din_int-1)
    await acc_random(dut, data, din_width, din_int, dout_width, dout_int,acc_len,iters,thresh)
    dut.rst <= 1;
    dut.din_valid <= 0
    await ClockCycles(dut.clk, 1)
    dut.rst <= 0
    await ClockCycles(dut.clk, 2)
    
    print("Overflow test") 
    data = np.ones([2**(dout_int-din_int+1), 2])*2**(din_int-1)-1
    res = await acc_overflow(dut, data, din_width, din_int, dout_width, dout_int,2**(dout_int-din_int)+2**2-1,2 ,thresh)
    for i in range(len(res)):
        assert (res[i] == (2**(dout_width-1)-1)/(2.**dout_pt)), "fail in {}".format(i)
    print("Pass!")
    dut.rst <= 1;
    dut.din_valid <= 0
    await ClockCycles(dut.clk, 1)
    dut.rst <= 0
    await ClockCycles(dut.clk, 2)
    
    print("underflow test")
    data = -np.ones([2**(dout_int-din_int+1), 2])*2**(din_int-1)
    res = await acc_overflow(dut, data, din_width, din_int, dout_width, dout_int,2**(dout_int-din_int)+2**2-1,2 ,thresh)
    for i in range(len(res)):
        assert (res[i] == (-2**(dout_width-1))/(2.**dout_pt)), "fail in {}".format(i)
    



async def acc_random(dut, data, din_width=16, din_int=8, dout_width=32, dout_int=16, 
                   acc_len=30,iters=10 ,thresh=0.2):
    #data = -(np.random.random([acc_len, iters]))*2**(din_int-1)
    out = []
    dut.rst <= 0
    for i in range(int(iters)):
        dut.din_eof <= 0
        dut.din_sof <= 1
        dat = two_comp_pack(data[:,i], din_width, din_int)
        for j in range(int(acc_len)-1):
            dut.din <= int(dat[j])
            dut.din_valid <=1
            await ClockCycles(dut.clk,1)
            dut.din_sof <= 0
            ##
            valid = dut.dout_valid.value
            if(valid):
                out.append(int(dut.dout.value))
        dut.din_eof <= 1;
        dut.din <= int(dat[-1])
        await ClockCycles(dut.clk,1)
    out = np.array(out)
    result = two_comp_unpack(out, dout_width, dout_int)
    for i in range(len(result)):
        #print("Python result: "+str(np.sum(data[:,i])))
        #print("Verilog result: "+str(result[i]))
        #print("")
        assert (np.abs(np.sum(data[:,i])-result[i])<thresh), "fail in {}".format(i)
    print("Pass!")
    return 1

async def acc_overflow(dut, data, din_width=16, din_int=8, dout_width=32, dout_int=16, 
                   acc_len=30,iters=10 ,thresh=0.2):
    #data = -(np.random.random([acc_len, iters]))*2**(din_int-1)
    out = []
    dut.rst <= 0
    for i in range(int(iters)):
        dut.din_eof <= 0
        dut.din_sof <= 1
        dat = two_comp_pack(data[:,i], din_width, din_int)
        for j in range(int(acc_len)-1):
            dut.din <= int(dat[j])
            dut.din_valid <=1
            await ClockCycles(dut.clk,1)
            dut.din_sof <= 0
            ##
            valid = dut.dout_valid.value
            if(valid):
                out.append(int(dut.dout.value))
        dut.din_eof <= 1;
        dut.din <= int(dat[-1])
        await ClockCycles(dut.clk,1)
    out = np.array(out)
    result = two_comp_unpack(out, dout_width, dout_int)
    """
    for i in range(len(result)):
        print("Python result: "+str(np.sum(data[:,i])))
        print("Verilog result: "+str(result[i]))
        print("")
        #assert(result[i]==) 
        #assert (np.abs(np.sum(data[:,i])-result[i])<thresh), "fail in {}".format(i)
    print("Pass!")
    """
    return result

