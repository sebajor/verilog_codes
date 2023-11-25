import cocotb
import pytest, os
import numpy as np
import cocotb_test.simulator
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def delay_test(dut):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    
    dut.din.value =0
    await ClockCycles(dut.clk, 10)
    
    ##get the actual parameters
    DELAY_VALUE =(os.environ.get("DELAY_VALUE"), "8")
    #print(dir(dut))
    #print(getattr(dut, 'din').value)
    print("asda")
    print(DELAY_VALUE)

    din_data = np.arange(128)
    for dat in din_data:
        dut.din.value =int(dat)
        await ClockCycles(dut.clk, 1)




##the pytest dont work  with well here.. dont know why
@pytest.mark.parametrize("parameters", [{"DELAY_VALUE":"1"}]
        )
def test_function(parameters):
    cocotb_test.simulator.run(
        verilog_sources=["delay.v"],                            ##verilog files
        toplevel="delay",                                       ##top level hdl
        module=os.path.splitext(os.path.basename(__file__))[0], ##cocotb python file (in this case the same file)
        parameters=parameters
        )


