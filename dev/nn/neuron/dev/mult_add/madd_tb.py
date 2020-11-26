import cocotb, struct
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb.binary import BinaryValue
import numpy as np

def int2bin(in_data, bin_pt):
    dat = (in_data*2**bin_pt).astype(int)
    bin_data = struct.pack('>'+str(len(in_data))+'h', *dat)
    return bin_data

def bin2int(in_data, bin_pt, parallel):
    output = np.array(struct.unpack('>'+str(parallel)+'i', in_data))/2**bin_pt
    return output


@cocotb.test()
async def madd_test(dut):
    clock = Clock(dut.clk,10,units='ns')
    cocotb.fork(clock.start())
    din_pt = 10#14
    dout_pt =32-2*6-2#26 #dout-clog2(n_parallel+2*din_pt)
    d1 = BinaryValue(1)
    d2 = BinaryValue(1)
    do = BinaryValue()

    din1 = np.array([-1,-0.8, 0.8,1])
    din2 = np.array([1, 0.8, -0.8, -1])
    din1_b = int2bin(din1, din_pt)
    din2_b = int2bin(din2, din_pt)
    d1.set_buff(din1_b)
    d2.set_buff(din2_b)
    dut.din1 <= d1
    dut.din2 <= d2
    for i in range(10):
        await ClockCycles(dut.clk, 1)
        out_val_int = bin2int(dut.dout.value.buff, dout_pt, 1)
        print(np.sum(din1*din2))
        print(out_val_int)
        print("\n")

