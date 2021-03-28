import cocotb, struct
import numpy as np
from cocotb.clock import Clock
from cocotb.binary import BinaryValue
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge, Timer




@cocotb.test()
async def i2c_master_w_test(dut):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    dut.rst <= 0
    np.random.seed(100)
    dev_addr = np.random.randint(0, 127)
    reg_addr = np.random.randint(0, 255)
    data = np.random.randint(0, 255)
    print("dev addr: %x" %dev_addr)
    print("reg addr: %x" %reg_addr)
    print("data: %x" %data)
    
    test1 = await i2c_dev(dut, dev_addr,reg_addr,data, ack=[0,0,0])
    print_result(test1)
    #print(test1)
    """
    dut.dev_addr <= dev_addr
    dut.reg_addr <= reg_addr
    dut.data <= i2c_data
    dut.sda_in <= 0
    dut.send <= 0
    await ClockCycles(dut.clk, 3)
    dut.send <= 1;
    test1 = await i2c_dev(dut)
    """
    #await ClockCycles(dut.clk, 1)
    #dut.send <= 0
    #await ClockCycles(dut.clk, 3000)


def print_result(test_out):
    vals = ["start", "dev_addr","write", "ack1", "reg addr", "ack2","data", "ack3", "stop"]
    for i in range(len(vals)):
        print(vals[i]+" : "+str(test_out[i]))

async def i2c_dev(dut, dev_addr_gold, reg_addr_gold, data_gold, ack=[0,0,0]):
    """ the output has a 1 if the sub task is correct
    output: [start, dev_addr,w, ack1, reg addr, ack2, data, ack3, stop]
    """
    dut.sda_in <=1
    output = np.zeros(9)
    dut.dev_addr <= dev_addr_gold
    dut.reg_addr <= reg_addr_gold
    dut.data <= data_gold
    dut.rst <= 0
    dut.send<=0
    await ClockCycles(dut.clk, 3)
    dut.send <= 1
    ##start condition
    start = await i2c_start(dut)
    dut.send <=0
    if(start):
        stop = await i2c_stop(dut)
        if(~stop):
            output[8] = 1
        return output
    output[0] = 1
    ##device address
    dev_addr_hw = await i2c_word(dut)
    if((dev_addr_hw>>1)==dev_addr_gold):
        output[1] = 1
    if(((dev_addr_hw)&1)==0):
        output[2] = 1
    ##acknowledge
    ack1 = await i2c_ack(dut, ack[0])
    if(ack1):
        #nack
        stop = await i2c_stop(dut)
        if(~stop):
            output[8] = 1
        return output
    output[3] = 1
    ##reg addr
    reg_addr_hw = await i2c_word(dut)
    if(reg_addr_hw==reg_addr_gold):
        output[4] = 1
    #ack2
    ack2 = await i2c_ack(dut, ack[1])
    if(ack2):
        #nack
        stop = await i2c_stop(dut)
        if(~stop):
            output[8] = 1
        return output
    output[5] = 1
    ##data
    data_hw = await i2c_word(dut)
    if(data_hw==data_gold):
        output[6] = 1
    ##ack3
    ack3 = await i2c_ack(dut, ack[2])
    if(ack3):
        #nack
        stop = await i2c_stop(dut)
        if(~stop):
            output[8] = 1
        return output
    output[7] = 1 
    ##stop
    stop = await i2c_stop(dut)
    if(~stop):
        output[8] = 1
    return output


async def i2c_start(dut): 
    await FallingEdge(dut.sda_out)
    scl_val = dut.scl_out.value 
    if(int(scl_val)==0):
        print("No start condition :(")
        return 1
    else:
        return 0


async def i2c_stop(dut):
    await RisingEdge(dut.sda_out)
    scl_val = dut.scl_out.value
    if(int(scl_val)==0):
        print("Wrong stop condition!")
        return 1
    return 0


async def i2c_word(dut):
    data = np.zeros(8)
    for i in range(8):
        await RisingEdge(dut.scl_out)
        sda_val = dut.sda_out.value
        data[i] = int(sda_val)
    data = np.packbits(data.astype(bool))
    return data


async def i2c_ack(dut, ack_val):
    dut.sda_in <= ack_val;    #ack
    await RisingEdge(dut.scl_out)
    sda_val = dut.sda_in.value  #this is given by the simulator
    return int(sda_val)

