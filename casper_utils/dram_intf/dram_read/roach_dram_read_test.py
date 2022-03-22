import numpy as np
import cocotb,sys
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.clock import Clock
sys.path.append('../../../cocotb_python/')
from two_comp import two_comp_pack, two_comp_unpack, pack_multiple, unpack_multiple
from roach_dram import roach_dram

###
###     Author:Sebastian Jorquera
###

@cocotb.test()
async def roach_dram_read_test(dut, iters=2**14, burst_read=10):
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
    await ClockCycles(dut.clk, 10)

    test_data = np.random.randint(2**32-1, size=2**12)
    ##test_data = np.arange(2**12)
    print(test_data)
    dram_inst = roach_dram(dut,2**12, init_mem=test_data)

    cocotb.fork(dram_inst.dram_behaviour(dut, iters*1000))

    cocotb.fork(read_data(dut, test_data))

    dut.rst.value =1
    await ClockCycles(dut.clk,1)
    dut.rst.value =0
    await ClockCycles(dut.clk,1)


    dut.read_en.value = 1
    #dut.rwn.value = 1
    for i in range(400):
        end = int(dut.finish.value)
        if(end):
            break
        dut.next_burst.value = 1
        await RisingEdge(dut.burst_done)
        dut.next_burst.value = 0
        await ClockCycles(dut.clk,100)
    await ClockCycles(dut.clk, 50)
    ##now we are going to read the same data 
    
    dut.rst.value =1
    await ClockCycles(dut.clk, 1)
    dut.rst.value =0
    ##read the first burst
    await ClockCycles(dut.clk,1)
    dut.next_burst.value = 1
    await RisingEdge(dut.burst_done)
    dut.next_burst.value = 0
    await ClockCycles(dut.clk,100)
    
    #repeat the same first burst
    dut.repeat_burst.value = 1
    await ClockCycles(dut.clk,1)
    dut.repeat_burst.value = 0
    await ClockCycles(dut.clk,1)
    dut.next_burst.value = 1
    await RisingEdge(dut.burst_done)
    dut.next_burst.value = 0
    await ClockCycles(dut.clk,100)
    
    #continue reading the following burst
    dut.next_burst.value = 1
    await RisingEdge(dut.burst_done)
    dut.next_burst.value = 0
    await ClockCycles(dut.clk,100)


    



async def read_data(dut, gold):
    count =0
    while(count<len(gold)):
        valid = int(dut.read_valid.value)
        if(valid):
            dout = int(dut.aux0.value)
            print("gold:%i \t rtl:%i" %(gold[count], dout))
            assert (dout==gold[count]), "Error"
            count +=1
        await ClockCycles(dut.clk, 1)

