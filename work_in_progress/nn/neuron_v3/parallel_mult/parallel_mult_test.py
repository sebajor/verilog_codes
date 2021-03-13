import cocotb, struct
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
from cocotb.binary import BinaryValue
import numpy as np


def din_pkt(din, bin_pt):
    """for this test we use input as 2bytes signed
        dat: numpy array with the mults 
        bin_pt: binary point
    """
    dat = (din*2**bin_pt).astype(int)
    bin_data = struct.pack('>'+str(len(din))+'h', *dat)
    return bin_data

def dout_unpack(dout, bin_pt, parallel):
    """ We take the output as an int
    """
    length = parallel*4-len(dout)
    dout = length*b'\x00'+dout
    out = np.array(struct.unpack('>'+str(parallel)+'i', dout))
    out = out/2**bin_pt
    return out


@cocotb.test()
async def parallel_mult_test(dut, bin_pt=15, parallel=4, iters=20, tresh=0.25):
    clock = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clock.start())
    np.random.seed(10)
    din1 = np.random.random(parallel)
    din2 = np.random.random(parallel)
    din1_b = din_pkt(din1, bin_pt)
    din2_b = din_pkt(din2, bin_pt)
    #create the binary values
    d1 = BinaryValue()
    d2 = BinaryValue()
    dout = BinaryValue()
    d1.set_buff(din1_b)
    d2.set_buff(din2_b)
    dut.din_valid <= 1
    gold_values = []
    dout_values = []
    for i in range(iters):
        dut.din1 <= d1
        dut.din2 <= d2
        await ClockCycles(dut.clk, 1)
        gold_values.append(din1*din2)
        valid = dut.dout_valid.value
        
        if(bool(valid&1)):
            out = dut.dout.value
            dout.integer = out
            out = dout_unpack(dout.buff, bin_pt*2, parallel)
            dout_values.append(out)
        ##update input values
        din1 = np.random.random(parallel)
        din2 = np.random.random(parallel)
        din1_b = din_pkt(din1, bin_pt)
        din2_b = din_pkt(din2, bin_pt)
        d1.set_buff(din1_b)
        d2.set_buff(din2_b)


    for i in range(len(dout_values)):
        #print("Verilog values:"+str(dout_values[i]))
        #print("Float values :"+str(gold_values[i]))
        print('Gold-Calculated: '+str(np.abs(gold_values[i]-dout_values[i])))
        assert (np.abs(np.sum(dout_values[i]-gold_values[i]))<tresh), "fail in {}".format(i)
