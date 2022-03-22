import numpy as np
import cocotb,sys
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
sys.path.append('../../../../cocotb_python')
from two_comp import two_comp_pack, two_comp_unpack, pack_multiple, unpack_multiple
from itertools import cycle

###
###     Author: Sebastian Jorquera
###

@cocotb.test()
async def roach_dram_write_test(dut, iters=1024, din_width=32, multiplex_in=3,
        dout_width=288, multiplex_out=9, burst_write=50, sleep_write=100,
        continous=0):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())

    dut.din.value =0
    dut.din_valid.value =0;
    dut.rst.value =0
    dut.en_write.value = 0
    await ClockCycles(dut.clk, 10)

    ##create test data
    din = np.arange(iters*multiplex_in)
    cocotb.fork(read_data(dut, din, din_width, multiplex_out))
    await write_data(dut, din, burst_write, sleep_write, continous)


async def read_data(dut, gold, din_width, multiplex_out):
    addr_counter = 0
    counter =0
    val_state =0
    prev_val = 0
    while(1):
        prev_val = val_state
        valid = dut.cmd_valid.value
        rwn = dut.rwn.value
        if(valid and not rwn):
            val_state=1
            if(prev_val):
                #dout = dut.dram_data.value
                #data = unpack_multiple(dout, multiplex_out, din_width)
                #print(addr_counter)
                dout0 = int(dut.dout0.value)
                dout1 = int(dut.dout1.value)
                dout2 = int(dut.dout2.value)
                dout3 = int(dut.dout3.value)
                dout4 = int(dut.dout4.value)
                dout5 = int(dut.dout5.value)
                dout6 = int(dut.dout6.value)
                dout7 = int(dut.dout7.value)
                dout8 = int(dut.dout8.value)
                dout = [dout0,dout1,dout2,dout3,dout4,dout5,dout6,dout7,dout8]
                for dat in dout:
                    print("gold:%i \t rtl:%i"%(gold[counter], dat))
                    assert (dat == gold[counter])
                    counter+=1
                dram_addr = dut.dram_addr.value
                assert (dram_addr==addr_counter)
                addr_counter +=1
        else:
            val_state = 0
        await ClockCycles(dut.clk,1)
        if(counter==(len(gold)-1)):
            break

async def write_data(dut, data, burst_write, sleep_write, continous=0):
    dut.en_write.value = 1
    data = data.reshape([-1,3])
    if(continous):
        for i in range(data.shape[0]):
            dat = pack_multiple(data[i,:], 3, 32)
            dut.din.value = int(dat)
            dut.din_valid.value = 1
            await ClockCycles(dut.clk,1)
        return 1
    else:
        counter =0
        while(counter<data.shape[0]):
            dut.din_valid.value = 0
            await ClockCycles(dut.clk, sleep_write)
            dut.din_valid.value = 1
            for i in range(burst_write):
                if(counter<len(data)):
                    dat = pack_multiple(data[counter,:],3,32) 
                    dut.din.value = int(dat)
                    await ClockCycles(dut.clk,1)
                    counter +=1
                else:
                    break
        dut.din_valid.value = 0
        return 1
