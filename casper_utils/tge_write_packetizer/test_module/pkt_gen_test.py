import numpy as np
import cocotb, sys
sys.path.append('../../../cocotb_python')
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
from two_comp import two_comp_pack, two_comp_unpack, pack_multiple, unpack_multiple
from itertools import cycle


@cocotb.test()
async def pkt_gen_test(dut, sim_cycles=2**16, write_len=512, sleep_write=2048, 
        sleep_cycles=10, pkt_len=108, data_width=32, multiplex_out=2, 
        multiplex_in=4):
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
    gold = np.arange(write_size)
    gold = np.hstack([[0xaabbccdd, 0xaabbccdd, 0xaabbccdd, 0xaabbccdd], gold])
    gold = cycle(gold)
    await ClockCycles(dut.clk,1)
    while(1):
        valid = int(dut.dout_valid.value)
        eof = int(dut.dout_eof)
        if(eof):
            assert (valid ==1) , 'eof high but valid not!!!'
        if(valid):
            tx = int(dut.dout.value)
            tx0, tx1 = unpack_multiple(tx, multiplex_out, data_width)
            gold0 = next(gold)
            gold1 = next(gold)
            print('rtl: %i \t gold: %i' %(tx0, gold0))
            print('rtl: %i \t gold: %i \n' %(tx1, gold1))
            assert (tx0==gold0), "Error"
            assert (tx1==gold1), "Error"
        await ClockCycles(dut.clk,1)






