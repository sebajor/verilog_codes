import numpy as np
import cocotb
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
import sys
sys.path.append('../../../cocotb_python/')
from two_comp import two_comp_pack, two_comp_unpack, pack_multiple, unpack_multiple
from itertools import cycle


@cocotb.test()
async def pkt_gen_test(dut, sim_cycles=2**16, write_len=512, sleep_write=512*19, 
        sleep_cycles=10, pkt_len=108, data_width=8, multiplex_out=1, 
        multiplex_in=16):
    #setup dut
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    dut.en.value =0;
    dut.rst.value =0;

    dut.burst_len.value = write_len-1;
    dut.sleep_write.value = sleep_write;

    dut.sleep_cycles.value = sleep_cycles;
    dut.pkt_len.value = pkt_len-1

    await ClockCycles(dut.clk, 10)
    dut.en.value = 1
    await ClockCycles(dut.clk, 1)
    cocotb.fork(read_data(dut, write_len*multiplex_in, multiplex_out, data_width))
    await ClockCycles(dut.clk, sim_cycles)
   

async def read_data(dut, write_size, multiplex_out, data_width):
    count =0
    gold = np.arange(write_size)
    print(len(gold))
    gold = np.hstack(([ 0xdd,0xdd,0xdd,0xdd,
                        0xdd,0xdd,0xdd,0xdd,
                        0xdd,0xdd,0xdd,0xdd,
                        0xdd,0xdd,0xdd,0xdd], gold.flatten()))
    gold = cycle(gold)
    await ClockCycles(dut.clk,1)
    while(1):
        valid = int(dut.dout_valid.value)
        eof = int(dut.dout_eof)
        if(eof):
            assert (valid ==1) , 'eof high but valid not!!!'
        if(valid):
            tx0 = int(dut.dout.value)
            gold0 = next(gold)
            print('rtl: %x \t gold: %x' %(tx0, gold0%256))
            assert (tx0==(gold0%256)), "Error"
        await ClockCycles(dut.clk,1)

