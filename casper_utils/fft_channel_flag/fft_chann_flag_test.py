import cocotb
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
import numpy as np


async def configure(dut, flags, din_width=32 ,streams=8):
    """ flags = [fft_channels]
    """
    flags_words = flags.reshape([-1, streams])
    for i in range(flags_words.shape[0]):
        dat =0
        for j in range(streams):
            dat = dat+(int(flags_words[i,j])<<j)
        dut.config_flag <= dat;
        dut.config_num <= i
        dut.config_en <=1
        await ClockCycles(dut.clk, 1)
    dut.config_en <= 0
    return 1



@cocotb.test()
async def fft_chann_flag_test(dut, din_width=32, streams=8, fft_channels=128,iters=64):
    cocotb.fork(Clock(dut.clk, 10, units='ns').start())
    dut.sync_in<=0;
    dut.din <=0;
    dut.config_en <=0
    dut.config_num <=0
    dut.config_flag <=0;
    await ClockCycles(dut.clk, 5)
    flags = np.zeros(fft_channels)
    flags[3] = 1
    flags[8] = 1
    flags[16] = 1
    await configure(dut, flags, din_width, streams)
    dut.sync_in <= 1
    await ClockCycles(dut.clk,1)
    dut.sync_in <= 0
    for i in range(iters):
        dat = 0
        for j in range(streams):
            dat = dat|(8*i+j)<<(32*j)
        dut.din <= dat;
        await ClockCycles(dut.clk,1)
       

