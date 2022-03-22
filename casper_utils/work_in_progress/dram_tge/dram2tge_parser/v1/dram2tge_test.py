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
    cocotb.fork(write_counter(dut, iters))
    await read_counter(dut, iters)


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

async def read_counter(dut, iters):
    gold =0
    for i in range(iters):
        await ClockCycles(dut.clk, 1)
        val = dut.tge_data_valid;
        if(val==1):
            tge0 = int(dut.tge0.value)
            tge1 = int(dut.tge1.value)
            assert (tge0 == gold*2)
            assert (tge1 == gold*2+1)
            gold +=1
