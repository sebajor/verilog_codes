import numpy as np
import cocotb, sys
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
from itertools import cycle
from roach_dram import roach_dram


@cocotb.test()
async def r_dram_one_gbe_test(dut, addr=12, burst_read=128, pkt_len=1024,
        sleep_cycles=10):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    
    np.random.seed(10)
    #
    dut.rst.value = 0
    dut.repeat_burst.value =0
    dut.read_en.value =0
    dut.burst_len.value = burst_read
    dut.next_burst.value =0
    dut.dram_data.value =0
    dut.rd_valid.value =0

    dut.pkt_len.value = pkt_len-1
    dut.sleep_cycles.value = sleep_cycles-1
    await ClockCycles(dut.clk, 10)
    

    test_data = np.random.randint(2**32-1, size=2**12)
     

