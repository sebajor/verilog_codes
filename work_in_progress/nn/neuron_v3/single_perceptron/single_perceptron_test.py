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
async def single_perceptron_test(dut, iters=128, thresh=0.1):
    #bias value
    bias = 0#0.5#-1.123
    #dut parameter 
    din_width = 8
    din_int = 1
    w_width = 16
    w_int = 2
    w_addrs = 512
    bias_width = 16
    bias_int = 4
    dout_width = 8
    dout_int = 4
    #derived parameters
    din_pt = din_width-din_int
    w_pt = w_width-w_int
    dout_pt = dout_width-dout_int

    types = ['b','h','i','q']
    din_type = types[int(din_width/8-1)]
    w_type = types[int(w_width/8-1)]
    clk = Clock(dut.clk, 10, "ns")
    cocotb.fork(clk.start())
    np.random.seed(20)
    
    bias_arr = np.array([bias,0])
    bias_b =two_comp_pack(bias_arr, bias_width, bias_int)
    bias_b = bias_b[0]
    dut.bias <= int(bias_b)
    dut.rst <= 0
    
    ##
    gold_vals = []
    out_vals = []

    #dut.bias <= int()
    for i in range(iters):
        dat_din = -(np.random.random(w_addrs)-0.5)*2**(din_int-1)
        dat_w = (np.random.random(w_addrs)-0.5)*2**(w_int-1)
        #dat_din = np.ones(w_addrs)/16.
        #dat_w = np.ones(w_addrs)/16.
        din_q = (dat_din*2**din_pt).astype(int)/2**din_pt
        w_q = (dat_w*2**w_pt).astype(int)/2**w_pt
        #din_b = din_pkt(dat_din, din_pt, dtype=din_type)
        #w_b = din_pkt(dat_w, w_pt, dtype=w_type)
        din_b = two_comp_pack(dat_din, din_width, din_int)
        w_b = two_comp_pack(dat_w, w_width, w_int)
        gold_vals.append(np.sum(din_q*w_q)+bias)
        for j in range(w_addrs):
            dut.din_valid <= 1
            dut.din <= int(din_b[j])
            dut.weight <= int(w_b[j])
            await ClockCycles(dut.clk, 1)
            valid = dut.dout_valid.value;
            if(int(valid)):
                out = int(dut.dout.value)
                out = np.array(out)
                out = two_comp_unpack(out, dout_width, dout_int)
                out_vals.append(out)
    
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

    max_val = 2**(dout_int-1)-1
    for i in range(1,dout_pt+1):
        max_val = max_val+(2**(-i))
        
    gold_vals = np.array(gold_vals)
    for i in range(len(out_vals)):
        soft_out = gold_vals[i]
        ##print outputs for debbug
        """
        if(soft_out<0):
            print("Python output : 0")
        else:
            print("Phyton Output "+str(soft_out))
        print("Verilog Output: "+str(out_vals[i]))
        """
        ##
        if(soft_out<0):
            soft_out = 0
        ##saturation
        if(soft_out>max_val):
            soft_out = max_val
        print(np.abs(soft_out-out_vals[i])) 
        assert (np.abs(soft_out-out_vals[i])<thresh), "fail in {}".format(i)
    print("Pass!")









