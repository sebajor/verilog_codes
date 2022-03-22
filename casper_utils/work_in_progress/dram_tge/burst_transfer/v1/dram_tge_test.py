import cocotb
import numpy as np
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
import queue


@cocotb.test()
async def dram_tge_test(dut, burst_size=3,tge_pkt_size=32,wait_pkt=10):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    np.random.seed(10)

    dut.rst <= 1;   dut.en <=0
    dut.dram_burst_size <= burst_size;
    dut.tge_pkt_size <= tge_pkt_size;
    dut.wait_pkt <= wait_pkt;
    dut.dram0<=0; dut.dram1<=0; dut.dram2<=0; dut.dram3<=0
    dut.dram4<=0; dut.dram5<=0; dut.dram6<=0; dut.dram7<=0
    dut.dram8<=0
    dut.dram_valid <=0
    dut.dram_ready <=0;
    await ClockCycles(dut.clk,1)
    dut.rst <= 1;
    await ClockCycles(dut.clk, 1)
    dut.rst <=0
    await ClockCycles(dut.clk,1)
    cocotb.fork(dram_read(dut)) 
    dut.en <= 1
    await tge_write(dut)

async def dram_read(dut):
    dram_reqs = queue.Queue()
    flag =0
    delay_rsp = 0
    while(1):
        dut.dram_ready <=1
        req = int(dut.dram_request.value)
        if(req==1):
            addr = int(dut.dram_addr.value)
            dram_reqs.put(addr)
            if(flag ==0):
                flag =1
                delay_rsp = np.random.randint(10)
        if((delay_rsp==0) & flag):
            if(dram_reqs.empty()):
                flag =0
                dut.dram_valid <=0
            else:
                dut.dram_valid<=1
                val = dram_reqs.get()
                dut.dram0 <= val*9
                dut.dram1 <= val*9+1
                dut.dram2 <= val*9+2
                dut.dram3 <= val*9+3
                dut.dram4 <= val*9+4
                dut.dram5 <= val*9+5
                dut.dram6 <= val*9+6
                dut.dram7 <= val*9+7
                dut.dram8 <= val*9+8
        if(delay_rsp!=0):
            dut.dram_valid <=0
            delay_rsp -=1
        await ClockCycles(dut.clk,1)


async def tge_write(dut):
    count =0
    while(1):
        val = int(dut.tge_data_valid.value)
        if(val):
            tge0 = int(dut.tge0.value)
            tge1 = int(dut.tge1.value)
            tge2 = int(dut.tge2.value)
            tge3 = int(dut.tge3.value)
            tge4 = int(dut.tge4.value)
            tge5 = int(dut.tge5.value)
            tge6 = int(dut.tge6.value)
            tge7 = int(dut.tge7.value)
            assert (tge0== (count*8))
            assert (tge1== (count*8+1))
            assert (tge2== (count*8+2))
            assert (tge3== (count*8+3))
            assert (tge4== (count*8+4))
            assert (tge5== (count*8+5))
            assert (tge6== (count*8+6))
            assert (tge7== (count*8+7))
            count +=1
        end = int(dut.finish.value)
        if(end==1):
            break
        await ClockCycles(dut.clk,1)
        
        
         

            


