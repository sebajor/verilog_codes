import cocotb, struct
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge,FallingEdge, ClockCycles
from cocotb.binary import BinaryValue
import numpy as np

def int2bin(in_data, bin_pt):
    dat = int(in_data*2**bin_pt)
    bin_data = struct.pack('>i', dat)
    return bin_data

def bin2int(in_data, bin_pt):
    output = np.array(struct.unpack('>h', in_data))/2**bin_pt
    return output



@cocotb.test()
async def relu_tb(dut):
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.fork(clock.start())
    in_pt = 32-8
    out_pt = 16-4
    din = 12
    din_b = int2bin(din, in_pt)
    d1 = BinaryValue()
    d1.set_buff(din_b)
    dut.din <= d1
    dut.din_valid <=1
    await ClockCycles(dut.clk, 1)
    out_val = bin2int(dut.dout.value.buff, out_pt)
    print('dout: '+str(out_val))
    din = -9
    din_b = int2bin(din, in_pt)
    d1.set_buff(din_b)
    dut.din <= d1
    await ClockCycles(dut.clk, 1)
    out_val = bin2int(dut.dout.value.buff, out_pt)
    print('dout: '+str(out_val))
    await ClockCycles(dut.clk, 1)
    out_val = bin2int(dut.dout.value.buff, out_pt)
    print('dout: '+str(out_val))

