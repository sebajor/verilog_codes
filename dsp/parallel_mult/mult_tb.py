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
    dat = (in_data*2**bin_point).astype(int)
    bin_data = struct.pack('>'+str(len(in_data))+'h', *dat); 
    return bin_data

def bin2int(in_data, bin_point):
    ##dat = struct.unpack('>'+str(len(in_data)/4)+'i', in_data)
    ##int_data = dat/2.**bin_point
    """Esta parte no funciona!!
    parallel = 4; mask=0xFFFFFFFF
    out = np.zeros(parallel)
    for i in range(parallel):
        out[i] = ((in_data>>i)&mask)
    bin_data  = struct.pack('>4I', *(out.astype(int)))
    out = np.array(struct.unpack('>4i', bin_data))
    output = out/(2.**bin_point)
    return output
    """
    #ahora si funca chuchetumare!!!
    parallel=4;
    #out = np.zeros(parallel)
    #for i in range(parallel):
    #    out[i] = int(in_data[32*(i+1):32*i], 2)
    #output = out/2.**bin_point
    output = np.array(struct.unpack('>4i',in_data))/2**bin_point
    return output

@cocotb.test()
async def mult_tb(dut):
    clock = Clock(dut.clk, 10,units='ns')
    cocotb.fork(clock.start())
    bin_pt = 14
    din1 = np.array([-1,1.2, 0.2, -0.5])
    din2 = np.array([-1,-0.5, 0.2, 0.3])
    din1_b = int2bin(din1,bin_pt)
    din2_b = int2bin(din2,bin_pt)
    d1 = BinaryValue(1); d1.set_buff(din1_b)
    d2 = BinaryValue(1); d2.set_buff(din2_b) 
    dut.din1 <= d1; dut.din2 <= d2;
    do = BinaryValue();
    await ClockCycles(dut.clk,1)
    await ClockCycles(dut.clk,1)
    for i in range(10):
        dut.din1 <= d1
        dut.din2 <= d2
        await ClockCycles(dut.clk, 1)
        out_val = dut.dout.value#dut.dout.value #?
        do.integer = out_val
        out_val_int = bin2int(do.buff, 28)
        print(out_val_int)
        assert(1==1)

        
