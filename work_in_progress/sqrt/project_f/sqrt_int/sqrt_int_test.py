import numpy as np
import cocotb
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock

@cocotb.test()
async def sqrt_int_test(dut, din_width=8, iters=255):
    cocotb.fork(Clock(dut.clk, 10, units='ns').start())
    dut.din <=0
    dut.din_valid <=0
    await ClockCycles(dut.clk, 5)
    np.random.seed(20)
    cycles = int(din_width/2)
    for i in range(iters):
        #din = np.random.randint(2**din_width-1)
        din = i
        dut.din <= din;
        dut.din_valid <=1
        await ClockCycles(dut.clk, 1)
        dut.din_valid <=0
        await ClockCycles(dut.clk, cycles+1)
        out = int(dut.dout.value)
        print("gold: %.2f \t rtl: %i" %(np.sqrt(din), out))
        assert int(np.sqrt(din)) == out, "Error"
