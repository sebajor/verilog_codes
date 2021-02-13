import numpy as np
import struct, cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb.binary import BinaryValue
from scipy.special import expit
import matplotlib.pyplot as plt

def din_pkt(din, dtype='h'):
    """ din is numpy array without the binary point (ie is the actual data
        multiplied by 2**bin_pt)
    """
    dat = (din).astype(int)
    bin_data = struct.pack('>'+str(len(din))+dtype, *dat)
    return bin_data

def dout_unpack(dout, dout_width,dout_pt):
    dtype = ['b','h','i','q']
    ind = int(dout_width/8)
    length = ind-len(dout)
    dout = length*b'\x00'+dout
    out = np.array(struct.unpack('>'+dtype[ind-1], dout))
    out = 1.*out/2**dout_pt
    return out


def gold_sigmoid(gold_input):
    """ 
    """
    out = expit(gold_input)
    return out


@cocotb.test()
async def sigmoid_test(dut,din_width=16, din_int=4, dout_width=8, dout_int=1, thresh=0.02):
    din_pt = din_width-din_int
    dout_pt = dout_width-dout_int
    np.random.seed(10)
    clock = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clock.start())
    await increasing_input(dut, din_width, din_pt, dout_width, dout_pt, thresh)




async def increasing_input(dut, din_width, din_pt, dout_width, dout_pt, thresh):
    din = BinaryValue()
    dout = BinaryValue()
    data = np.arange(2**din_width)
    neg = data[2**(din_width-1):]
    ##reorder the data as in 2 complement
    data = np.hstack([neg , data[0:2**(din_width-1)]])
    gold_in = np.linspace(-2**(din_width-1), 2**(din_width-1), 2**din_width, endpoint=0)/(2**din_pt) 
    gold_values = gold_sigmoid(gold_in)
    dout_values = []
    for i in range(len(data)):
        dut.din <= int(data[i])
        dut.din_valid <= 1
        await ClockCycles(dut.clk, 1)
        valid = dut.dout_valid.value
        if(valid):
            out = dut.dout.value
            dout.integer = out
            out = dout_unpack(dout.buff,dout_width, dout_pt)
            dout_values.append(out)
    for i in range(len(dout_values)):
        #print("Verilog values:"+str(dout_values[i]))
        #print("Float values :"+str(gold_values[i]))
        print('Gold-Calculated: '+str(np.abs(gold_values[i]-dout_values[i])))
        assert (np.abs(np.sum(dout_values[i]-gold_values[i]))<thresh), "fail in {}".format(i)
    #return
    plt.plot(dout_values, label='hdl')
    plt.plot(gold_values, label='python')
    plt.legend()
    plt.savefig("comparison.png")
    #plt.show()
    return 



