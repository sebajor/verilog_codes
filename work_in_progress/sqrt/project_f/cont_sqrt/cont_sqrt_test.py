import numpy as np
import cocotb
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock


async def write_beat_data(dut, din_width, din_pt, data, beat_size, wait):
    gold_val = np.sqrt(data/2.**din_pt)
    for i in range(len(data)):
        if(i%beat_size==0):
            for j in range(wait):
                dut.din_valid <=0
                await ClockCycles(dut.clk, 1)
                val = int(dut.dout_valid.value)
                if(val):
                    out = int(dut.dout.value)/2.**din_pt
                    print("gold: %.2f \t rtl: %f" %(gold_val[0], out))
                    gold_val = np.delete(gold_val,0)
        dut.din <= int(data[i]);
        dut.din_valid <=1
        await ClockCycles(dut.clk, 1)
        val = int(dut.dout_valid.value)
        if(val):
            out = int(dut.dout.value)/2.**din_pt
            print("gold: %.2f \t rtl: %f" %(gold_val[0], out))
            gold_val = np.delete(gold_val,0)


@cocotb.test()
async def sqrt_fix_test(dut, din_width=8, din_pt=6, iters=255, thresh=0.01):
    cocotb.fork(Clock(dut.clk, 10, units='ns').start())
    dut.din <=0
    dut.din_valid <=0
    dut.rst <=0
    await ClockCycles(dut.clk, 5)
    np.random.seed(20)
    cycles = int(din_width+din_pt/2)
    gold_val = np.sqrt(np.arange(iters)/2.**din_pt)
    """
    for i in range(iters):
        din = i
        dut.din <= din;
        dut.din_valid <=1
        await ClockCycles(dut.clk, 1)
        dut.din_valid <=0
        val = int(dut.dout_valid.value)
        if(val):
            out = int(dut.dout.value)/2.**din_pt
            #print("gold: %.2f \t rtl: %f" %(gold_val[0], out))
            gold_val = np.delete(gold_val,0)
        #await ClockCycles(dut.clk, 1)
        #assert ((np.sqrt(din)-out)<thresh), "Error"
    """
    beat_size = 10
    wait = 5
    data = np.arange(iters)
    beat = await write_beat_data(dut, din_width, din_pt, data, beat_size, wait)
