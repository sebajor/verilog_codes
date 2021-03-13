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
async def macc_test(dut):
    clock = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clock.start())
    din_pt = 14
    dout_pt = 32-8#14
    d1 = BinaryValue()
    d2 = BinaryValue()
    do = BinaryValue()
    
    np.random.seed(7)
    """
    din1 = np.array([-1, -0.8, 0.8, 1])
    din2 = np.array([1,0.8, -0.8, -1])
    #din1 = np.random.random(4)#-0.5
    #din2 = np.random.random(4)#-0.5
    din1_b = int2bin(din1, din_pt)
    din2_b = int2bin(din2, din_pt)
    d1.set_buff(din1_b)
    d2.set_buff(din2_b)
    dut.din1 <= d1
    dut.din2 <= d2
    """
    dut.en <= 1
    dut.last <= 0
    dut.rst <= 0
    acc = 0
    for i in range(10):
        din1 = 2*np.random.random(4)-1 #0.5
        din2 = 2*np.random.random(4)-1#0.5
        din1_b = int2bin(din1, din_pt)
        din2_b = int2bin(din2, din_pt)
        d1.set_buff(din1_b)
        d2.set_buff(din2_b)
        dut.din1 <= d1
        dut.din2 <= d2   
        acc = acc+np.sum(din1*din2)
        await ClockCycles(dut.clk, 1)
        out_val_int = bin2int(dut.dout.value.buff, dout_pt, 1)
        print(np.sum(din1*din2))
        print(out_val_int)
        print("\n")
    dut.last <= 1
    acc = acc+np.sum(din1*din2)
    await ClockCycles(dut.clk, 1)
    dut.last <= 0
    dut.en <=0
    print('acc: '+str(acc))
    print('finish first burst')
    din1 = np.array([-1, -0.8, 0.8, 1])
    din2 = np.array([1,0.8, -0.8, -1])
    #din1 = np.random.random(4)#-0.5
    #din2 = np.random.random(4)#-0.5
    din1_b = int2bin(din1, din_pt)
    din2_b = int2bin(din2, din_pt)
    d1.set_buff(din1_b)
    d2.set_buff(din2_b)
    dut.din1 <= d1
    dut.din2 <= d2

    await ClockCycles(dut.clk, 2)
    acc =0#np.sum(din1*din2) #0 ##esta considerando el en =0 tambien!
    dut.en <= 1
    for i in range(14):
        din1 = 2*np.random.random(4)-1 #0.5
        din2 = 2*np.random.random(4)-1#0.5
        din1_b = int2bin(din1, din_pt)
        din2_b = int2bin(din2, din_pt)
        d1.set_buff(din1_b)
        d2.set_buff(din2_b)
        dut.din1 <= d1
        dut.din2 <= d2   
        acc = acc+np.sum(din1*din2)
        await ClockCycles(dut.clk, 1)
        dut.en <= 0
        await ClockCycles(dut.clk, 3)
        dut.en <= 1
        out_val_int = bin2int(dut.dout.value.buff, dout_pt, 1)
        print(np.sum(din1*din2))
        print(out_val_int)
        print("\n")
    dut.last <= 1
    acc = acc+np.sum(din1*din2)
    await ClockCycles(dut.clk, 1)
    dut.last <= 0
    dut.en <=0
    print('acc = '+str(acc))
    print('finish second burst')
    await ClockCycles(dut.clk, 1)
    for i in range(10):
        await ClockCycles(dut.clk, 1)
        out_val_int = bin2int(dut.dout.value.buff, dout_pt, 1)
        #print(np.sum(din1*din2))
        print(out_val_int)
        print("\n")
    print('acc = '+str(acc))

