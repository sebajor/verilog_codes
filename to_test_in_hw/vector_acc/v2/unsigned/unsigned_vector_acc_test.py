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
async def unsigned_vector_acc_test(dut, vec_len=64, acc_len=10, test_len=4, din_width = 16, dout_width=32):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    dut.new_acc <= 0
    dut.din <=0
    dut.din_valid <=0
    await ClockCycles(dut.clk, 1)
    ufix_test = await unsigned_input(dut)
    #fix_test = await signed_input(dut, din_width, dout_width)

async def signed_input(dut,din_width, dout_width, vec_len=64,acc_len=5, test_len=4):
    data = (np.random.randn(vec_len, acc_len)*2**12).astype(int)
    out_vals = await write_signed(dut, data, din_width, dout_width)
    gold = np.sum(data, axis=1)
    for i in range(test_len):
        data = (np.random.randn(vec_len, acc_len)*2**12).astype(int)
        out_vals = await write_signed(dut, data, din_width, dout_width)
        for j in range(len(out_vals)):
            #print("gold:%i \t out_vals:%i"%(gold[j],out_vals[j]))
            assert (out_vals[j]==gold[j]), "fail in {}".format(j)
        gold = np.sum(data,axis=1)
        print("iter %i ok"%i)



async def unsigned_input(dut, vec_len=64,acc_len=5, test_len=4):
    #data = (np.random.random([vec_len, acc_len])*2**16).astype(int)
    aux = np.arange(vec_len)+1
    data = np.repeat(aux, acc_len).reshape([vec_len, acc_len])
    #out_vals = await write(dut, data)
    #out_vals = await write_spaced(dut, data)
    out_vals = await write_continous(dut, data)
    gold = np.sum(data, axis=1)
    for i in range(test_len):
        #data = (np.random.random([vec_len, acc_len])*2**16).astype(int)
        data = np.repeat(aux, acc_len).reshape([vec_len, acc_len])
        #out_vals = await write(dut, data)
        #out_vals = await write_spaced(dut, data)
        out_vals = await write_continous(dut, data)
        for j in range(len(out_vals)):
            assert (out_vals[j]==gold[j]), "fail in {}".format(j)
        gold = np.sum(data,axis=1)
        print("iter %i ok"%i)

async def write_continous(dut, dat):
    """
        dat: [vec_len, acc_len]
        wait: wait between each vec_len
    """
    dut.new_acc <= 1
    #await ClockCycles(dut.clk,1)
    #dut.new_acc <= 0
    vec_len, acc_len = dat.shape
    out_vals = []
    for i in range(acc_len):
        for j in range(vec_len):
            dut.din <= int(dat[j,i])
            dut.din_valid <=1
            await ClockCycles(dut.clk,1)
            dut.new_acc <=0
            valid = int(dut.dout_valid.value)
            if(valid):
                out = int(dut.dout.value)
                out_vals.append(out)
        dut.din_valid <= 0
    return out_vals
    
async def write_spaced(dut, dat, wait=64, space=4):
    """
        dat: [vec_len, acc_len]
        wait: wait between each vec_len
    """
    dut.new_acc <= 1
    #await ClockCycles(dut.clk,1)
    #dut.new_acc <= 0
    vec_len, acc_len = dat.shape
    out_vals = []
    for i in range(acc_len):
        for j in range(vec_len):
            dut.din <= int(dat[j,i])
            dut.din_valid <=1
            await ClockCycles(dut.clk,1)
            valid = int(dut.dout_valid.value)
            dut.new_acc <= 0
            if(valid):
                out = int(dut.dout.value)
                out_vals.append(out)
            for i in range(space):
                dut.din_valid <= 0;
                await ClockCycles(dut.clk,1)
                valid = int(dut.dout_valid.value)
                if(valid):
                    out = int(dut.dout.value)
                    out_vals.append(out)
        dut.din_valid <= 0
        await ClockCycles(dut.clk, wait)
    return out_vals

    
    
async def write(dut, dat, wait=64):
    """
        dat: [vec_len, acc_len]
        wait: wait between each vec_len
    """
    dut.new_acc <= 1
    #await ClockCycles(dut.clk,1)
    #dut.new_acc <= 0
    vec_len, acc_len = dat.shape
    out_vals = []
    for i in range(acc_len):
        for j in range(vec_len):
            dut.din <= int(dat[j,i])
            dut.din_valid <=1
            await ClockCycles(dut.clk,1)
            valid = int(dut.dout_valid.value)
            dut.new_acc <= 0
            if(valid):
                out = int(dut.dout.value)
                out_vals.append(out)
        dut.din_valid <= 0
        await ClockCycles(dut.clk, wait)
    return out_vals
    

async def write_signed(dut, dat,din_width,dout_width, wait=64):
    """
        dat: [vec_len, acc_len]
        wait: wait between each vec_len
    """
    dut.new_acc <= 1
    await ClockCycles(dut.clk,1)
    dut.new_acc <= 0
    vec_len, acc_len = dat.shape
    out_vals = []
    for i in range(acc_len):
        data = two_comp_pack(dat[:,i], din_width,din_width)
        #print(data)
        for j in range(vec_len):
            #dut.din <= int(dat[j,i])
            dut.din <= int(data[j])
            dut.din_valid <=1
            await ClockCycles(dut.clk,1)
            valid = int(dut.dout_valid.value)
            if(valid):
                out = np.array(int(dut.dout.value))
                out_vals.append(out)
        dut.din_valid <= 0
        await ClockCycles(dut.clk, wait)
        out_vals = np.array(out_vals)
        out_vals = two_comp_unpack(out_vals, dout_width, dout_width)
    return out_vals
