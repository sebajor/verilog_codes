import os
import pytest
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
import numpy as np
import cocotb_test.simulator
import logging 



@cocotb.test()
async def adder_test(dut):
    #dut._log.error("sdasd!")
    #, din_width=16, iters=1024):
    #din_width = 16
    din_width = len(dut.din0)
    din_width = int(dut.DIN_WIDTH)
    cocotb.log.error("Starting test din_width:%.2f"%din_width)
    #os.system("echo "+din_width+">> file")
    iters = 1024
    clk = Clock(dut.clk, 10, units='ns')
    #cocotb.fork(clk.start())
    cocotb.start_soon(clk.start())

    dut.din0.value =0
    dut.din1.value = 0
    dut.din_valid.value = 0

    np.random.seed(123)
    dat0 = np.random.randint(2**(din_width)-1,size=iters)#-2**(din_width-1)
    dat1 = np.random.randint(2**(din_width)-1,size=iters)#-2**(din_width-1)
    data = [dat0,dat1]
    
    gold = dat0+dat1
    cocotb.start_soon(read_data(dut, gold))
    await write_data(dut, data)

async def write_data(dut, data):
    for i in range(len(data[0])):
        dut.din0.value = int(data[0][i])
        dut.din1.value = int(data[1][i])
        dut.din_valid.value = 1
        await ClockCycles(dut.clk, 1)
    dut.din_valid.value = 0

async def read_data(dut, gold):
    count =0
    while(count < len(gold)):
        valid = int(dut.dout_valid.value)
        if(valid):
            dout = int(dut.dout.value)
            assert( dout == gold[count]), "Error!"
            count +=1
        await ClockCycles(dut.clk,1)

@pytest.mark.parametrize("din_width", [8,16,32])
def test_adder(request, din_width):
    #logging.basicConfig()
    log = logging.getLogger("tb_logger")
    log.error("din_width: %.4f"%(din_width))
    tests_dir = os.path.abspath(os.path.dirname(__file__))
    dut = 'adder_tb'
    verilog_sources = [
        os.path.join(tests_dir, dut+".v"),
        os.path.join(tests_dir,"adder.v")
            ]
    parameters = {}
    parameters['DIN_WIDTH'] = din_width

    #extra_env = {f'PARAM_{k}': str(v) for k, v in parameters.items()}
    cocotb_test.simulator.run(
        module='adder_test',
        python_search=[tests_dir],
        verilog_sources = verilog_sources,
        toplevel= dut,
        parameters = parameters,
        #extra_env=extra_env,
            )

