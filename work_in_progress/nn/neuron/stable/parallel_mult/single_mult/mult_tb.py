import cocotb, struct
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, ClockCycles
from cocotb.binary import BinaryValue
import numpy as np


def int2bin(in_data, bin_point):
    """in_data must be a list with the values!
    This function returns the binary representation of the data 
    and concatenate it
    """
    dat = int(in_data*2**bin_point)
    bin_data = struct.pack('>h', dat); 
    return bin_data

def bin2int(in_data, bin_point):
    ##dat = struct.unpack('>'+str(len(in_data)/4)+'i', in_data)
    ##int_data = dat/2.**bin_point
    bin_data  = struct.pack('>I', in_data)
    out = np.array(struct.unpack('>i', bin_data))
    output = out/(2.**bin_point)
    return output


@cocotb.test()
async def mult_tb(dut):
    clock = Clock(dut.clk, 10,units='ns')
    cocotb.fork(clock.start())
    bin_pt = 14
    din1 = -0.3
    din2 = 0.9
    din1_b = int2bin(din1,bin_pt); din2_b = int2bin(din2, bin_pt)
    d1 = BinaryValue(1); d1.set_buff(din1_b)
    d2 = BinaryValue(1); d2.set_buff(din2_b) 
    dut.din1 <= d1; dut.din2 <= d2;
    #dat1_l = [1, 0.4, -0.3, 1.1, 0.2, -1.25, 1.4, -1, -0.4]
    #dat2_l = [0.2, 0.1, 0.3, 0.8, 0.4, -1, -0.9, -0.4]
    await ClockCycles(dut.clk,1)
    await ClockCycles(dut.clk,1)
    for i in range(10):
        dut.din1 <= d1
        dut.din2 <= d2
        await ClockCycles(dut.clk, 1)
        out_val = dut.dout.value #?
        out_val_int = bin2int(out_val, 28)
        print(out_val_int)
        assert(1==1)

        
