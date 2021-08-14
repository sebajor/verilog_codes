import cocotb
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock

@cocotb.test()
async def dram2tge_test(dut, iters=64):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    #initial values
    dut.en <=0
    dut.rst <=0
    dut.dram_valid<=0
    dut.dram_ready <=0
    dut.dram0<=0; dut.dram1<=0; dut.dram2<=0; dut.dram3<=0
    dut.dram4<=0; dut.dram5<=0; dut.dram6<=0; dut.dram7<=0
    dut.dram8<=0
    await ClockCycles(dut.clk, 4)
    dut.rst <= 1;
    await ClockCycles(dut.clk, 1)
    dut.rst <=0;
    await ClockCycles(dut.clk, 2)
    dut.en <= 1
    await ClockCycles(dut.clk, 3)
    await write_counter(dut, iters)
    await ClockCycles(dut.clk,2)
    dut.rst <= 1
    await ClockCycles(dut.clk, 1)
    dut.rst <=0
    await write_counter(dut, iters)



async def write_counter(dut, iters):
    dut.dram_ready <=1
    ##start writing data
    count =0
    gold=0
    for i in range(iters):
        req = int(dut.dram_request.value)
        if(req):
            dut.dram_valid <= 1;
            dut.dram0 <= 9*count
            dut.dram1 <= 9*count+1
            dut.dram2 <= 9*count+2
            dut.dram3 <= 9*count+3
            dut.dram4 <= 9*count+4
            dut.dram5 <= 9*count+5
            dut.dram6 <= 9*count+6
            dut.dram7 <= 9*count+7
            dut.dram8 <= 9*count+8
            count +=1
        else:
            dut.dram_valid <=0;
        await ClockCycles(dut.clk, 1)
        val = dut.tge_data_valid;
        if(val==1):
            tge0 = int(dut.tge0.value)
            tge1 = int(dut.tge1.value)
            tge2 = int(dut.tge2.value)
            tge3 = int(dut.tge3.value)
            tge4 = int(dut.tge4.value)
            tge5 = int(dut.tge5.value)
            tge6 = int(dut.tge6.value)
            tge7 = int(dut.tge7.value)
            assert (tge0 == gold*8)
            assert (tge1 == gold*8+1)
            assert (tge2 == gold*8+2)
            assert (tge3 == gold*8+3)
            assert (tge4 == gold*8+4)
            assert (tge5 == gold*8+5)
            assert (tge6 == gold*8+6)
            assert (tge7 == gold*8+7)
            gold +=1
            ##print("%i \t %i \t %i \t %i" %(tge0,tge1,tge2,tge3))
            ##print("%i \t %i \t %i \t %i" %(tge4,tge5,tge6,tge7))
 
    
