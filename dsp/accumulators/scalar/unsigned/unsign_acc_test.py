import numpy as np
import cocotb
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge
from cocotb.clock import Clock
import sys


@cocotb.test()
async def unsigned_acc_test(dut, iters=128, din_width=16, dout_width=32, acc_len=10,
        cont=0, burst_len=10):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    
    #setup dut
    dut.din.value =0
    dut.din_valid.value =0
    dut.acc_done.value =0
    await ClockCycles(dut.clk, 4)

    #gen data
    data = np.random.randint(0, 2**8, size=[acc_len, iters])
    gold = np.sum(data, axis=0)
    
    cocotb.fork(read_data(dut, gold, dout_width, 0))
    await write_data(dut, data, cont, burst_len)
    

async def write_data(dut, data, cont, burst_len):
    if(cont):
        dut.acc_done.value = 1
        await ClockCycles(dut.clk, 1)
        dut.acc_done.value = 0
        for i in range(data.shape[1]):
            for j in range(data.shape[0]):
                dut.din_valid.value =1;
                dut.din.value = int(data[j][i])
                await ClockCycles(dut.clk, 1)
                if(j==(data.shape[0]-1)):
                    dut.acc_done.value =1
                else:
                    dut.acc_done.value =0
        dut.din_valid.value = 0
    else:
        count=0
        for i in range(data.shape[1]):
            for j in range(data.shape[0]):
                dut.din_valid.value =1;
                dut.din.value = int(data[j][i])
                await ClockCycles(dut.clk, 1)
                count +=1
                if(count == burst_len):
                    count =0
                    dut.din_valid.value = 0
                    dut.acc_done.value =0
                    await ClockCycles(dut.clk, np.random.randint(20))
                if(j==(data.shape[0]-1)):
                    dut.acc_done.value =1
                else:
                    dut.acc_done.value =0
        dut.din_valid.value = 0


async def read_data(dut, gold, dout_width, dout_pt):
    count =0
    while(count < len(gold)):
        valid = int(dut.dout_valid.value)
        if(valid):
            dout = int(dut.dout.value)
            print('gold: %i \t rtl: %i' %(gold[count], dout))
            assert (gold[count] == dout), "Error"
            count += 1
        await ClockCycles(dut.clk,1)



