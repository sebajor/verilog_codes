import numpy as np
import cocotb, sys, os
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.clock import Clock
import cocotb_test.simulator
import pytest
import sys
sys.path.append('/home/seba/Workspace/verilog_codes/cocotb_python/')
from two_comp import two_pack_multiple, two_comp_unpack

###
### Author: Sebastian Jorquera
###

@cocotb.test()
async def adder_tree_test(dut, iters=200):
    #hdl hyperparameters  
    data_width = int(dut.DATA_WIDTH)
    parallel = int(dut.PARALLEL)
    #data_type = str(dut.DATA_TYPE)
    
    cocotb.log.info("din width={:}, parallel{:}".format(data_width, parallel))
    clk = Clock(dut.clk,10, units='ns')
    cocotb.start_soon(clk.start())
    dut.din.value =0
    dut.din_valid.value = 0

    din = np.random.randint(size=iters*parallel, low=-(2**(data_width-1)-1), 
                             high=2**(data_width-1)).reshape((-1, parallel))
    #din = np.ones((iters, parallel))*-7
    gold = np.sum(din, axis=1)
    cocotb.start_soon(read_data(dut, gold, parallel, data_width))
    await write_data(dut, din, data_width)

async def read_data(dut, gold, parallel, data_width):
    dout_size = int(np.ceil(np.log2(parallel)))+data_width
    count = 0; count_valid = 0;
    while(count< len(gold)):
        valid = dut.dout_valid.value
        if(valid):
            assert(count_valid==(int(np.ceil(np.log2(parallel))+1)))
            dout = np.array(int(dut.dout.value))
            dout = two_comp_unpack(dout, dout_size, 0)
            print("gold: %.2f rtl:%.2f"%(gold[count], dout))
            cocotb.log.debug("gold: %.2f rtl:%.2f"%(gold[count], dout))
            assert(gold[count]==dout)
            count+=1
        else:
            count_valid+=1
        await ClockCycles(dut.clk,1)

async def write_data(dut, din, data_width):
    iters, parallel = din.shape
    for i in range(iters):
        din_dat = two_pack_multiple(din[i,:], data_width, 0)
        dut.din.value = int(din_dat)
        dut.din_valid.value = 1
        await ClockCycles(dut.clk,1)


@pytest.mark.parametrize("data_width", [2])
@pytest.mark.parametrize("parallel", [8, 7,10,12,16,21,32])
def test_adder_tree(request, data_width, parallel):
    tests_dir = os.path.abspath(os.path.dirname(__file__))
    prev_dir = os.path.split(tests_dir)[0]
    dut = 'adder_tree'
    verilog_sources = [
        os.path.join(tests_dir, dut+'_tb.v'),
        os.path.join(tests_dir, dut+'.v'),
        os.path.join(prev_dir, 'delay', 'delay.v')
        ]
    dut = dut+'_tb'
    parameters = {}
    parameters['DATA_WIDTH'] = data_width
    parameters['PARALLEL'] = parallel

    cocotb_test.simulator.run(
        module = 'adder_tree_test',
        verilog_sources = verilog_sources,
        toplevel = dut,
        parameters = parameters,
        timescale="1ns/1ns",    ##sometimes the clock doesnt start
        force_compile=True,     ##as we change parameters in the hdl we need to compile each time
        seed=10,
            )




