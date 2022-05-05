import cocotb
import numpy as np
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
import sys 
sys.path.append('../../../cocotb_python')
from two_comp import two_comp_pack, two_comp_unpack

###
###     Author: Sebastian Jorquera
###


@cocotb.test()
async def signed_cast_test(dut, din_width=16, din_pt=12, dout_width=8, dout_pt=4,
        iters=30, cont=1,burst_len=10):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    

    #setup dut
    dut.din.value = 0
    dut.din_valid.value =0
    await ClockCycles(dut.clk, 10)

    din = (np.random.random(iters)-0.5) *2**(din_width-din_pt-2)
    din_bin = two_comp_pack(din, din_width, din_pt)

    cocotb.fork(read_data(dut, din, dout_width, dout_pt))
    await write_data(dut, din_bin, cont, burst_len)
    
    #overflow
    dut.din.value = 2**(din_width-1)-1
    dut.din_valid.value  =1
    await ClockCycles(dut.clk, 5)
    #underflow
    dut.din.value = 2**(din_width-1)
    await ClockCycles(dut.clk, 5)

    

async def write_data(dut, data, cont, burst_len):
    if(cont):
        for i in range(len(data)):
            dut.din_valid.value = 1
            dut.din.value = int(data[i])
            await ClockCycles(dut.clk, 1)
        dut.din_valid.value =0 
    else:
        count = 0
        for i in range(len(data)):
            dut.din_valid.value = 1
            dut.din_re.value = int(data[i])
            await ClockCycles(dut.clk, 1)
            count +=1
            if( count==burst_len):
                count =0
                dut.din_valid.value = 0
                await ClockCycles(dut.clk, np.random.randint(20))
        dut.din_valid.value =0

async def read_data(dut, gold, dout_width, dout_pt):
    count =0
    while(count < len(gold)):
        valid = int(dut.dout_valid.value)
        if(valid):
            dout = int(dut.dout.value)
            dout = two_comp_unpack(np.array(dout), dout_width, dout_pt)
            print("gold: %.2f \t rtl:%.2f" %(gold[count], dout))
            count +=1
        await ClockCycles(dut.clk, 1)


