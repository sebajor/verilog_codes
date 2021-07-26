import numpy as np
import cocotb
from cocotb.triggers import ClockCycles, RisingEdge, Timer
from cocotb.clock import Clock

CLK_A = 8
CLK_B = 10

def setup_dut(dut):
    cocotb.fork(Clock(dut.clka, CLK_A, units='ns').start())
    fpga_clk = Clock(dut.clkb, CLK_B, units='ns')
    cocotb.fork(fpga_clk.start())
    dut.addra <=0
    dut.dina <=0
    dut.wea <=0
    dut.ena <=1
    dut.rsta <=0
    dut.addrb <=0
    dut.dinb <=0
    dut.web <=0
    dut.enb <=1
    dut.rstb <=0
    return 1

@cocotb.test()
async def unbalance_ram_test(dut, iters=32):
    base = 0xAABBCCDD<<32
    setup_dut(dut)
    await Timer(5*CLK_A, units='ns')
    await RisingEdge(dut.clka)
    ##write from porta 
    for i in range(iters):
        dut.addra <= i
        dut.dina <= (2*i) | ((2*i+1)<<32)
        dut.wea <= 1
        #await ClockCycles(dut.clka, 1)
        await Timer(CLK_A, units='ns')
    dut.wea <= 0
    ## read port a
    dut.flag <=1
    for i in range(iters):
        dut.addra <=i
        await Timer(CLK_A, units='ns')
        #await ClockCycles(dut.clka, 1)
        out = dut.douta.value
        print("%x"%out)
    #read port b
    await RisingEdge(dut.clkb)
    dut.flag <=0
    for i in range(iters*2):
        dut.addrb <=i
        await Timer(CLK_B, units='ns')
        #await ClockCycles(dut.clkb, 1)
        out = dut.doutb.value
        print("%x"%out)
    dut.addrb <=2
    dut.addra <=1
    await ClockCycles(dut.clkb,10)
    #write port b
    """
    dut.web <=1
    for i in range(2*iters):
        dut.addrb <= i;
        dut.dinb <= i;
        await ClockCycles(dut.clkb,1)
    dut.web <=0
    await RisingEdge(dut.clka)
    ##read port a
    for i in range(iters):
        dut.addra <= i
        await ClockCycles(dut.clka, 1)
        out = dut.douta.value
        out0 = out & (2**32-1)
        out1 = (out>>32) & (2**32-1);
        #print("%x \t %x "%(out0, out1))
    """

        




