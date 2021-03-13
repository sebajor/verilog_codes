import cocotb, struct
import numpy as np
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
from cocotb.binary import BinaryValue

def din_pkt(din, bin_pt, dtype='b'):
    """for this test we use input as 2bytes signed
        dat: numpy array with the mults
        bin_pt: binary point
    """
    dat = (din*2**bin_pt).astype(int)
    bin_data = struct.pack('>'+str(len(din))+dtype, *dat)
    return bin_data

def dout_unpack(dout, bin_pt, parallel, dtype='h'):
    """ We take the output as an int
    """
    length = parallel*2-len(dout)
    dout = length*b'\x00'+dout
    out = np.array(struct.unpack('>'+str(parallel)+dtype, dout))
    out = out/2**bin_pt
    return out

@cocotb.test()
async def signed_cast_test(dut, parallel=8 ,din_width=8, din_int=4, dout_width=16,
                            dout_int=3, iters=10):
    clk = Clock(dut.clk, 10, 'ns')
    cocotb.fork(clk.start())
    np.random.seed(10)
    ###
    din_pt = din_width-din_int
    dout_pt = dout_width-dout_int
    din = BinaryValue()
    dout = BinaryValue()
    dut.din_valid <= 1
    in_vals = []
    out_vals = []
    for i in range(iters):
        dat = (np.random.random(parallel)-0.5)*2**(din_int)
        #print("in vals")
        #print(dat)
        din_b = din_pkt(dat, din_pt)
        din_quant = np.array(struct.unpack('>'+str(parallel)+'b',din_b))/2**din_pt
        in_vals.append(din_quant)
        din.set_buff(din_b)
        dut.din <= din
        await ClockCycles(dut.clk, 1)
        valid = dut.dout_valid.value
        if(int(valid)):
            out = dut.dout.value
            dout.integer = out
            out = dout_unpack(dout.buff, dout_pt, parallel)
            out_vals.append(out)
            #print("out vals")
            #print(out)
            #print("")
    for i in range(len(out_vals)):
        print("in vals")
        print(in_vals[i])
        print("out vals")
        print(out_vals[i])
        print("")



