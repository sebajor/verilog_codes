import numpy as np
import struct, cocotb
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
from cocotb.binary import BinaryValue


def din_pkt(din, bin_pt, dtype='b'):
    """for this test we use input as 2bytes signed
        dat: numpy array with the mults
        bin_pt: binary point
        dtype: data type, only supported by struct b,h,i,q,B,H,I,Q
    """
    types = ['b','h','i', 'h']
    byte_size = types.index(dtype)+1
    dat = (din*2**bin_pt).astype(int)
    bin_data = struct.pack('>'+str(int(len(din)))+dtype, *dat)
    return bin_data

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
async def parallel_perceptron_test(dut, iters=128 ,thresh=0.1):
    ##bias value
    bias = 3.5#2.123
    ##dut parameters
    parallel = 8
    din_width = 8
    din_int = 1
    w_width = 16
    w_int = 1
    w_addrs = 64
    bias_width = 10
    bias_int = 4
    dout_width = 8
    dout_int = 4
    ##derived parameters
    din_pt = din_width-din_int
    w_pt = w_width-w_int
    bias_pt = bias_width-bias_int
    dout_pt = dout_width-dout_int

    

    ##
    types = ['b','h','i','q']
    din_type = types[int(din_width/8-1)]
    w_type = types[int(w_width/8-1)]
     

    clk = Clock(dut.clk, 10, "ns")
    cocotb.fork(clk.start())
    np.random.seed(10)

    ##
    din = BinaryValue()
    weight = BinaryValue()
    dout = BinaryValue()

    bias_arr = np.array([bias,0])
    bias_b =two_comp_pack(bias_arr, bias_width, bias_int)
    bias_b = bias_b[0]
    dut.bias <= int(bias_b)
    dut.rst <= 0
    
    gold_vals = []
    out_vals = []

    for i in range(int(iters)):
        gold = np.zeros(w_addrs)
        for j in range(w_addrs):
            dat_din = (np.random.random(parallel)-0.5)*2**(din_int-1)
            dat_w = (np.random.random(parallel)-0.5)*2**(w_int-1) 
            din_q = (dat_din*2**din_pt).astype(int)/2**din_pt
            w_q = (dat_w*2**w_pt).astype(int)/2**w_pt
            din_b = din_pkt(dat_din, din_pt, dtype=din_type)
            w_b = din_pkt(dat_w, w_pt, dtype=w_type)
            din_quant = np.array(struct.unpack('>'+str(parallel)+din_type,din_b))/2**din_pt
            w_quant = np.array(struct.unpack('>'+str(parallel)+w_type,w_b))/2**w_pt
            gold[j] = np.sum(din_quant*w_quant)

            din.set_buff(din_b)
            weight.set_buff(w_b)
            dut.din <= din
            dut.weight <= weight
            dut.din_valid <= 1
            await ClockCycles(dut.clk, 1)
            valid = dut.dout_valid.value;
            if(int(valid)):
                out = int(dut.dout.value)
                out = np.array(out)
                out = two_comp_unpack(out, dout_width, dout_int)
                out_vals.append(out)
        gold_vals.append(gold)
    
    ##wait some cycles to obtain the delayed output
    wait = 30
    for i in range(wait):
        valid = dut.dout_valid.value;
        if(int(valid)):
            out = int(dut.dout.value)
            out = np.array(out)
            out = two_comp_unpack(out, dout_width, dout_int)
            out_vals.append(out)
        await ClockCycles(dut.clk, 1)

        
    gold_vals = np.array(gold_vals)
    for i in range(len(out_vals)):
        #assert (np.abs(np.sum(gold_vals[i])-out_vals[i])<thresh), "fail in {}".format(i)
        soft_out = np.sum(gold_vals[i])+bias
        if(soft_out<0):
            soft_out = 0

        """
        if(soft_out<0):
            print("Python output : 0")
        else:
            print("Phyton Output "+str(soft_out))
        print("Verilog Output: "+str(out_vals[i]))
        """
        assert (np.abs(soft_out-out_vals[i])<thresh), "fail in {}".format(i)
    print("Pass!")
