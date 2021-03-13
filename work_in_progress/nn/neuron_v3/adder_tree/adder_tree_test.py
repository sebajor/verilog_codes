#!/usr/bin/python3

import struct, cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb.binary import BinaryValue
import numpy as np


def din_pkt(din, bin_pt):
    """ struct only support byte-sized values.. for this test we
        use signed chars
        din  : normalized data (-1,1) in a np.array
        bin_pt: binary point
    """
    dat = (din*2**bin_pt).astype(int)
    parallel = str(len(din))
    bin_data = struct.pack('>'+parallel+'b', *dat)
    return bin_data

def dout_unpack(dout, bin_pt):
    """ we suppouse an 32 bits output
        dout: binary value returned from the sim
    """
    length = 4-len(dout)
    dout = length*b'\x00'+dout
    out = struct.unpack('>i', dout)[0]/2**bin_pt
    return out


@cocotb.test()
async def adder_tree_tb(dut, bin_pt=7, parallel=10, treshold=0.05):
    iters = 10
    np.random.seed(12)
    ##start clock task
    clock = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clock.start())
    #define input data
    dat_in = BinaryValue()
    dat = np.random.random(parallel)
    bin_din = din_pkt(dat, bin_pt)
    dat_in.set_buff(bin_din)
    #define output variable
    dout = BinaryValue()
    gold_values = []
    out_vals = []
    val_out = int(np.log2(parallel))+parallel%2+1;
    valid = []
    print("valid out:"+str(val_out))
    for i in range(iters):
        dut.in_valid <= 1;
        dut.din <= dat_in;
        val_out -= 1
        dat = (dat*2**bin_pt).astype(int)/2**bin_pt #quantized gold data
        gold_values.append(np.sum(dat))
        dat = np.random.random(parallel)
        bin_din = din_pkt(dat, bin_pt)
        dat_in.set_buff(bin_din)
        await ClockCycles(dut.clk,1)
        ##wait until the output is valid (put a signal there!!)
        if(val_out<0):
            #out = dout_unpack(dut.dout.buff)
            out_value = dut.dout.value
            dout.integer = out_value
            out = dout_unpack(dout.buff, bin_pt)
            out_vals.append(out)
            valid.append(dut.out_valid)
    for i in range(len(out_vals)):
        print("verilog out: %.4f \t gold out: %.4f \t out_valid: %i" %(out_vals[i], gold_values[i], valid[i]))
        assert (np.abs(out_vals[i]-gold_values[i])<treshold), "fail in {}!!!".format(i)
    print("pass!")
