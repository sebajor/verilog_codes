import numpy as np
import cocotb, sys
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
sys.path.append('../../../cocotb_python')
from two_comp import two_comp_pack, two_comp_unpack, pack_multiple, unpack_multiple
from itertools import cycle

###
### Author: Sebastian Jorquera
###

@cocotb.test()
async def tge_write_packetizer(dut, iters=16, din_width=32, multiplex_in=4, 
        dout_width=64, multiplex_out=2, burst_write=200,
        sleep_write=2048, pkt_len=109, sleep_cycles=10):
    #setup dut
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())

    dut.din.value =0
    dut.din_valid.value =0;
    dut.rst.value =0
    dut.pkt_len.value = pkt_len-1
    dut.sleep_cycles.value = sleep_cycles-1

    #data = np.arange(burst_write*multiplex_in).reshape([-1,multiplex_in])
    data = np.random.randint(2**32-1, size=(burst_write*multiplex_in)).reshape([-1, multiplex_in])
    cocotb.fork(read_data(dut,data, burst_write*multiplex_in, multiplex_out, din_width, pkt_len))
    await write_data(dut, data, din_width, multiplex_in,iters, burst_write, sleep_write)




async def read_data(dut,gold,write_size, multiplex_out, din_width, pkt_len):
    counter =0
    #gold = np.arange(write_size)
    gold = np.hstack(([0xaabbccdd,0,0xaabbccdd,0], gold.flatten()))
    gold = cycle(gold)
    await ClockCycles(dut.clk,1)
    while(1):
        valid = int(dut.tx_valid.value)
        eof = int(dut.tx_eof)
        if((counter%pkt_len==0) and counter!=0):
            assert (eof==1), 'eof is not high when it should!'
        if(eof):
            assert (valid ==1) , 'eof high but valid not!!!'
        if(valid):
            tx = int(dut.tx_data.value)
            tx0, tx1 = unpack_multiple(tx, multiplex_out, din_width)
            aux0 = next(gold)
            aux1 = next(gold)
            print("gold: %.2f \t rtl:%.2f" %(aux0, tx0))
            print("gold: %.2f \t rtl:%.2f" %(aux1, tx1))
            assert (tx0==aux0), "Error"
            assert (tx1==aux1), "Error"
        await ClockCycles(dut.clk,1)


async def write_data(dut, data, din_width, multiplex_in,iters, burst_write, sleep_write):
    for i in range(iters):
        dut.din.value =0
        dut.din_valid.value =0
        await ClockCycles(dut.clk, sleep_write)
        dut.din.value = (0xaabbccdd+((0xaabbccdd)<<64))
        dut.din_valid.value = 1
        await ClockCycles(dut.clk, 1)
        for j in range(data.shape[0]):
            dat = pack_multiple(data[j,:], multiplex_in, din_width)
            dut.din.value = int(dat)
            dut.din_valid.value = 1
            await ClockCycles(dut.clk,1)

            

    

