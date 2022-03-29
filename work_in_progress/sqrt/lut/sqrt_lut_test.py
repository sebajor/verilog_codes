import numpy as np
import cocotb
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock

###
### Author:Sebastian Jorquera
###

@cocotb.test()
async def sqrt_lut_test(dut, din_width=16, din_pt=10, dout_width=10, dout_pt=6,
                        thresh=0.04, cont=0, burst_len=10):
    clock = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clock.start())
    dut.din.value = 0
    dut.din_valid.value =0
    await ClockCycles(dut.clk, 5)

    din = np.arange(2**din_width)

    gold= np.sqrt(din/2.**din_pt)

    cocotb.fork(read_data(dut, gold, dout_pt,thresh))
    await write_data(dut, din,cont, burst_len)


async def write_data(dut, data, cont, burst_len):
    count =0
    if(cont):
        for i in range(len(data)):
            dut.din_valid.value = 1
            dut.din.value = int(data[i])
            await ClockCycles(dut.clk, 1)
        dut.din_valid.value =0
    else:
        for i in range(len(data)):
            dut.din_valid.value =1
            dut.din.value = int(data[i])
            await ClockCycles(dut.clk,1)
            count +=1
            if(count==burst_len):
                count =0
                dut.din_valid.value =0
                await ClockCycles(dut.clk, np.random.randint(10))

async def read_data(dut, gold, dout_pt, thresh):
    count =0
    while(count<len(gold)):
        valid = int(dut.dout_valid.value)
        if(valid):
            dout = int(dut.dout.value)/2.**dout_pt
            print("gold:%.4f \t rtl:%.4f" %(gold[count], dout))
            assert (np.abs(dout-gold[count])<thresh), "Error!"
            count +=1
        await ClockCycles(dut.clk,1)

