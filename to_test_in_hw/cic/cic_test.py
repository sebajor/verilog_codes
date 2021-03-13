import cocotb, struct
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb.binary import BinaryValue
import numpy as np
import struct
import matplotlib.pyplot as plt


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
async def cic_test(dut):
    clock = Clock(dut.clk_in, 10, units='ns')
    cocotb.fork(clock.start())
    dut.test_number <= 0;
    dut.rst <= 0;
    dut.din <= 0;
    await ClockCycles(dut.clk_in, 4)
    ## impulse response, must be finite
    dut.din <= 1;
    await ClockCycles(dut.clk_in, 1)
    dut.din <= 0;
    for i in range(2**7):
        await ClockCycles(dut.clk_in, 1)
    ##test 2 step response, must be decimation**stages = 8^3=512=0x200
    dut.test_number <= 1;
    dut.din <= 1;
    await ClockCycles(dut.clk_in, 2**7)
    ##sinusoid input
    d1 = BinaryValue()
    k = 15          ## twiddle factor
    t = np.arange(1024)
    dat = np.sin(2*np.pi*t*k/1024.)
    #dat_bin = struct.pack('>1024h', *((dat*(2**15-1)).astype(int)))
    dut.rst <= 1;
    dut.din <=0;
    await ClockCycles(dut.clk_in, 24)
    dut.rst <= 0;
    dut.test_number <= 2
    await ClockCycles(dut.clk_in, 4)
    f = open('out', 'wb')
    for i in range(2):
        clk_dly =0
        for j in range(1024):
            if(bool(dut.clk_out.value)&(~bool(clk_dly))):
                f.write(dut.dout.value.buff)
            dat_bin = struct.pack('>h', (dat[j]*(2**15-1)).astype(int))
            d1.set_buff(dat_bin)
            dut.din <= d1
            clk_dly = dut.clk_out.value
            await ClockCycles(dut.clk_in, 1)
    f.close()


