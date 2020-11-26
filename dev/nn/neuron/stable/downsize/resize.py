import cocotb, struct
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb.binary import BinaryValue
import numpy as np


def int2bin(in_data, bin_pt):
    dat = (in_data*2**bin_pt).astype(int)
    bin_data = struct.pack('>'+str(len(in_data))+'i', *dat)
    return bin_data

def bin2int(in_data, bin_pt, parallel):
    #dat = (2*(parallel-len(in_data))*(b"\x00"))
    #data = b"".join([dat,in_data])
    #print(data)
    output = np.array(struct.unpack('>'+str(parallel)+'h', in_data))/2**bin_pt
    return output

@cocotb.test()
async def resize(dut):
    clock = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clock.start())
    din_pt = 21
    dout_pt = 5 #21-(32-16)
    d1 = BinaryValue(1);
    do = BinaryValue() 
    din1 = np.random.rand(4)*16
    din1_b = int2bin(din1, din_pt)
    d1.set_buff(din1_b)
    dut.din <= d1
    np.random.seed(23)
    await ClockCycles(dut.clk,1)
    for i in range(10):
        din1 = np.random.rand(4)*21
        din1_b = int2bin(din1, din_pt)
        d1.set_buff(din1_b)
        dut.din <= d1
        await ClockCycles(dut.clk,1)
        out_val_int = bin2int(dut.dout.value.buff,dout_pt,4)
        print(out_val_int)
        print("\n")
        print(din1)
        #out_val = dut.dout.value
        #do.buff = int(dut.dout)
        #print(do.buff)
        #print(dut.dout.value.buff)
        din1 = np.random.rand(4)*21
        din1_b = int2bin(din1, din_pt)
        d1.set_buff(din1_b)
        dut.din <= d1
        await ClockCycles(dut.clk,1)
        out_val_int = bin2int(dut.dout.value.buff,dout_pt,4)
        print(out_val_int)
        print("\n")
        print(din1)

