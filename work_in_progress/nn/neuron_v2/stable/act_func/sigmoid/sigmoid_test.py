import cocotb, struct
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge,FallingEdge, ClockCycles
from cocotb.binary import BinaryValue
import numpy as np

def int2bin(in_data, bin_pt):
    dat = int(in_data*2**bin_pt)
    bin_data = struct.pack('>b', dat)
    return bin_data

def bin2int(in_data, bin_pt):
    output = np.array(struct.unpack('>h', in_data))/2**bin_pt
    return output



@cocotb.test()
async def sigmoid_test(dut):
    clock = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clock.start())
    din_pt = 4
    out_pt = 15
    do = BinaryValue()
    di = BinaryValue()
    din = 1.2
    din_b = int2bin(din, din_pt)
    di.set_buff(din_b)
    dut.din <= di
    dut.din_valid <= 0
    """
    await ClockCycles(dut.clk, 1)
    out_val_int = bin2int(dut.dout.value.buff, out_pt)
    print(out_val_int)
    await ClockCycles(dut.clk, 1)
    out_val_int = bin2int(dut.dout.value.buff, out_pt)
    print(out_val_int)
    await ClockCycles(dut.clk, 1)
    dut.din_valid <= 1
    out_val_int = bin2int(dut.dout.value.buff, out_pt)
    print(out_val_int)
    await ClockCycles(dut.clk, 1)
    out_val_int = bin2int(dut.dout.value.buff, out_pt)
    print(out_val_int)
    await ClockCycles(dut.clk, 1)
    out_val_int = bin2int(dut.dout.value.buff, out_pt)
    print(out_val_int)
    """
    ##start testing, for simplcity i take 2**8 addresses
    data = np.zeros(2**8)
    ##negative values
    for i in range(2**7):
        dut.din <= 2**7+i;
        dut.din_valid <= 1;
        await ClockCycles(dut.clk, 1)
        out_val_int = bin2int(dut.dout.value.buff, out_pt)
        data[i] = out_val_int

    ##positive values
    for i in range(2**7):
        dut.din <= i;
        dut.din_valid <= 1;
        await ClockCycles(dut.clk, 1)
        out_val_int = bin2int(dut.dout.value.buff, out_pt)
        data[2**7+i] = out_val_int
    
    np.savetxt('data', data)







