import cocotb, random, string
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge


@cocotb.test()
async def pattern_search_test(dut, iters=192, header='hello world', msg="red car"):
    cocotb.fork(Clock(dut.clk, 10, units='ns').start())
    #
    dut.rst.value =0
    dut.din.value =0
    dut.din_valid.value =0
    await ClockCycles(dut.clk,1)
    
    ##generate random letters
    random.seed(10)
    letters = string.ascii_lowercase
    din = ''.join(random.choice(letters) for i in range(iters))
    insert = random.randint(0,iters-1) 



