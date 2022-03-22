import numpy as np
import cocotb
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock

###
###     Author: Sebastian Jorquera
###

@cocotb.test()
async def fifo_sync_test(dut, din_width=16, iters=32):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    dut.rst.value =0
    dut.wdata.value =0;
    dut.w_valid.value =0;
    dut.read_req.value =0;
    await ClockCycles(dut.clk, 3)
    np.random.seed(230)
    gold = np.random.randint(0, 2**16, size=iters)
    cocotb.fork(write_data(dut, gold))
    #await read_data(dut, gold)
    await read_beat(dut, gold)
    
async def write_data(dut, gold_data, full_en=1):
    index =0;
    prev_full = 0
    valid =0
    while (index<len(gold_data)-1):
        full = int(dut.full.value)
        if(~full & valid):
            index +=1
        if(full==0):
            dut.wdata.value = int(gold_data[index])
            valid = 1
            #dut.w_valid <= 1;
        elif(full_en):
            #dut.w_valid <=0
            valid =0
        #else:
            #dut.w_valid <=1
            #index+=1
        dut.w_valid.value = valid
        await ClockCycles(dut.clk, 1)

async def read_data(dut, gold_data):
    count =0;
    while(count < len(gold_data)):
        empty = int(dut.empty.value)
        if(empty==0):
            dut.read_req.value =1;
        else:
            dut.read_req.value =0;
        valid = int(dut.r_valid.value)
        if(valid ==1):
            out = int(dut.rdata.value)
            assert (out==gold_data[count])
            count  +=1;
        await ClockCycles(dut.clk, 1)


async def read_beat(dut, gold_data):
    count =0
    beat_count =0
    while(count < len(gold_data)):
        empty = int(dut.empty.value)
        if(empty==0):
            if(beat_count==0):
                dut.read_req.value =1;
                beat_count  = np.random.randint(10)
            else:
                dut.read_req.value =0;
                beat_count -=1
        else:
            dut.read_req.value =0;
        valid = int(dut.r_valid.value)
        if(valid ==1):
            out = int(dut.rdata.value)
            assert (out==gold_data[count])
            count  +=1;
        await ClockCycles(dut.clk, 1)
