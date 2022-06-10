import cocotb, sys
import numpy as np
from cocotb.clock import Clock 
from cocotb.triggers import ClockCycles
sys.path.append('../../cocotb_python')
from two_comp import *


def mov_avg_power(data, delay_line):
    out = []
    mov = np.zeros(delay_line)
    for dat in data:
        mov = np.roll(mov, 1)
        mov[0] = dat**2
        out.append(np.sum(mov)/delay_line)
    return np.array(out)


@cocotb.test()
async def avg_power_test(dut, iters=128, din_width=8, din_point=7, delay_line=32,
        thresh=0.5):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    dout_width = 2*din_width
    dout_point = 2*din_point
    
    np.random.seed(20)
    dut.rst.value =0
    dut.din.value =0
    dut.din_valid.value = 0
    await ClockCycles(dut.clk, 5)

    #input_data = np.ones(iters)-0.5
    f = 30
    input_data = 0.5*np.sin(2*np.pi*f*np.arange(iters)/iters)
    
    gold_data = mov_avg_power(input_data, delay_line)
    din_data = two_comp_pack(input_data, din_width, din_point)

    cocotb.fork(read_data(dut, gold_data, dout_width, dout_point, thresh))
    await write_data(dut, din_data)


async def write_data(dut, din):
    for dat in din:
        dut.din.value = int(dat)
        dut.din_valid.value = 1
        await ClockCycles(dut.clk, 1)


async def read_data(dut, gold_data, dout_width, dout_point, thresh):
    count = 0
    while(count < len(gold_data)):
        valid = dut.dout_valid.value 
        if(valid):
            out = int(dut.dout.value)
            out = out/2.**dout_point
            print("rtl: %.4f \t gold:%.4f" %(out, gold_data[count]))
            assert (np.abs(out-gold_data[count])<thresh)
            count +=1
        await ClockCycles(dut.clk, 1)

