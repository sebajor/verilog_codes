import numpy as np
import cocotb
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.clock import Clock

###
### Author: Sebastian Jorquera
###

@cocotb.test()
async def single_port_write_first_test(dut, din_width=18, addr=1024):
    clk = Clock(dut.clka, 10, units='ns')
    cocotb.fork(clk.start())

    #setup the starting values
    dut.addra.value =0 
    dut.dina.value =0
    dut.wea.value =0
    dut.ena.value = 1
    dut.rsta.value = 0
    await ClockCycles(dut.clka, 5)

    din = np.arange(addr)+1

    for i in range(addr):
        dut.addra.value = i
        dut.dina.value = int(din[i])
        dut.wea.value = 1
        await ClockCycles(dut.clka, 1)

    dut.wea.value =0
    for i in range(addr):
        dut.addra.value = i
        await ClockCycles(dut.clka, 1)
    
